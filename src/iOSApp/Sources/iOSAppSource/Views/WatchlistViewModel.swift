// pigapril/sio_ios_app/SIO_iOS_app-error_handle/src/iOSApp/Sources/iOSAppSource/Views/WatchlistViewModel.swift

import SwiftUI
import Combine

@MainActor
class WatchlistViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var selectedCategoryId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    
    // New properties for showing alerts
    @Published var showAlert: Bool = false
    @Published var alertMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()
    private var searchDebounceTimer: AnyCancellable?

    func fetchCategories() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let fetchedCategories = try await APIService.shared.fetchCategories()
                self.categories = fetchedCategories
                if let firstCategory = fetchedCategories.first, self.selectedCategoryId == nil {
                    self.selectedCategoryId = firstCategory.id
                }
            } catch {
                self.errorMessage = error.localizedDescription
                ErrorHandler.handle(error: error, component: "WatchlistViewModel.fetchCategories")
            }
            self.isLoading = false
        }
    }
    
    func createCategory(name: String) async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            self.errorMessage = "Category name cannot be empty."
            return
        }
        
        do {
            let newCategory = try await APIService.shared.createCategory(name: name)
            categories.append(newCategory)
            self.selectedCategoryId = newCategory.id // Select the new category
        } catch {
            self.errorMessage = error.localizedDescription
            ErrorHandler.handle(error: error, component: "WatchlistViewModel.createCategory")
        }
    }

    func addStock(symbol: String) async {
        guard let categoryId = selectedCategoryId else {
            self.errorMessage = "No category selected."
            return
        }
        
        // Prevent adding duplicates on the client-side
        if let category = categories.first(where: { $0.id == categoryId }), (category.stocks ?? []).contains(where: { $0.symbol == symbol }) {
            self.errorMessage = "\(symbol) is already in this category."
            return
        }

        do {
            let newStock = try await APIService.shared.addStock(categoryId: categoryId, symbol: symbol)
            if let index = categories.firstIndex(where: { $0.id == categoryId }) {
                if categories[index].stocks != nil {
                    categories[index].stocks?.append(newStock)
                } else {
                    categories[index].stocks = [newStock]
                }
            }
        } catch {
            self.errorMessage = error.localizedDescription
            ErrorHandler.handle(error: error, component: "WatchlistViewModel.addStock")
        }
    }
    
    func removeStock(from categoryId: String, at offsets: IndexSet) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == categoryId }) else { return }

        // Safely unwrap the stocks array before using it
        guard let stocks = categories[categoryIndex].stocks else { return }
        let stocksToDelete = offsets.map { stocks[$0] }

        Task {
            for stock in stocksToDelete {
                do {
                    try await APIService.shared.removeStock(categoryId: categoryId, itemId: stock.id)
                    // On success, safely remove from the optional local array
                    self.categories[categoryIndex].stocks?.removeAll(where: { $0.id == stock.id })
                } catch {
                    self.errorMessage = error.localizedDescription
                    ErrorHandler.handle(error: error, component: "WatchlistViewModel.removeStock")
                }
            }
        }
    }
    
    func searchStocks(keyword: String) {
        searchDebounceTimer?.cancel() // Cancel previous timer
        guard !keyword.isEmpty else {
            self.searchResults = []
            self.isSearching = false
            return
        }
        
        isSearching = true
        
        searchDebounceTimer = Just(keyword)
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] newKeyword in
                guard let self = self else { return }
                Task {
                    do {
                        self.searchResults = try await APIService.shared.searchStocks(keyword: newKeyword)
                    } catch {
                        self.errorMessage = error.localizedDescription
                        ErrorHandler.handle(error: error, component: "WatchlistViewModel.searchStocks")
                        self.searchResults = []
                    }
                    self.isSearching = false
                }
            }
    }

    func deleteCategory(at offsets: IndexSet) {
        let categoriesToDelete = offsets.map { categories[$0] }
        Task {
            for category in categoriesToDelete {
                do {
                    try await APIService.shared.deleteCategory(id: category.id)
                    categories.removeAll { $0.id == category.id }
                    // 如果刪除的是當前選中的分類，則選擇另一個
                    if selectedCategoryId == category.id {
                        selectedCategoryId = categories.first?.id
                    }
                    // 顯示成功 Toast
                    ToastManager.shared.show(
                        type: .success,
                        title: NSLocalizedString("watchlist.category.deleteSuccess", bundle: .module, comment: "")
                    )

                } catch {
                    // --- START OF CORRECTION ---

                    // 1. 取得本地化的錯誤訊息
                    let localizedMessage: String
                    if let appError = error as? AppError,
                       case .backendError(_, let message) = appError {
                        // 如果是後端來的特定錯誤，直接使用它的訊息
                        localizedMessage = message
                    } else {
                        // 否則，使用通用的本地化錯誤描述
                        localizedMessage = error.localizedDescription
                    }

                    // 2. 移除舊的 Alert 觸發程式碼 (這兩行是造成問題的關鍵)
                    // self.alertMessage = ... (REMOVE THIS LINE)
                    // self.showAlert = true (REMOVE THIS LINE)
                    
                    // 3. 改為呼叫 ToastManager 來顯示錯誤
                    ToastManager.shared.show(
                        type: .error,
                        title: NSLocalizedString("errors.DELETE_CATEGORY_FAILED", bundle: .module, comment: "Delete category failed title"), // 使用翻譯鍵
                        message: localizedMessage
                    )
                    
                    // 4. 錯誤日誌記錄保持不變
                    ErrorHandler.handle(error: error, component: "WatchlistViewModel.deleteCategory")
                    
                    // --- END OF CORRECTION ---
                }
            }
        }
    }

    func updateCategory(category: Category, newName: String) async {
        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else {
            self.errorMessage = "Category name cannot be empty."
            return
        }
        
        do {
            let updatedCategory = try await APIService.shared.updateCategory(id: category.id, name: newName)
            if let index = categories.firstIndex(where: { $0.id == category.id }) {
                categories[index].name = updatedCategory.name
            }
        } catch {
            self.alertMessage = error.localizedDescription // Set alert message for other errors
            self.showAlert = true // Show alert for other errors
            ErrorHandler.handle(error: error, component: "WatchlistViewModel.updateCategory")
        }
    }
}