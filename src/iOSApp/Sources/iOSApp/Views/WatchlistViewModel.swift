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

    private var cancellables = Set<AnyCancellable>()

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
        do {
            let newCategory = try await APIService.shared.createCategory(name: name)
            categories.append(newCategory)
        } catch {
            self.errorMessage = error.localizedDescription
            ErrorHandler.handle(error: error, component: "WatchlistViewModel.createCategory")
        }
    }

    func addStock(symbol: String) async {
        guard let categoryId = selectedCategoryId else { return }
        do {
            let newStock = try await APIService.shared.addStock(categoryId: categoryId, symbol: symbol)
            if let index = categories.firstIndex(where: { $0.id == categoryId }) {
                categories[index].stocks.append(newStock)
            }
        } catch {
            self.errorMessage = error.localizedDescription
            ErrorHandler.handle(error: error, component: "WatchlistViewModel.addStock")
        }
    }
    
    // ✅ **解決方案：新增 removeStock 函式**
    func removeStock(categoryId: String, itemId: String) async {
        do {
            try await APIService.shared.removeStock(categoryId: categoryId, itemId: itemId)
            // 直接從本地端移除，避免重新抓取所有資料，優化體驗
            if let categoryIndex = categories.firstIndex(where: { $0.id == categoryId }) {
                categories[categoryIndex].stocks.removeAll { $0.id == itemId }
            }
        } catch {
            self.errorMessage = error.localizedDescription
            ErrorHandler.handle(error: error, component: "WatchlistViewModel.removeStock")
        }
    }
    
    func searchStocks(keyword: String) {
        isSearching = true
        Task {
            do {
                self.searchResults = try await APIService.shared.searchStocks(keyword: keyword)
            } catch {
                self.errorMessage = error.localizedDescription
                ErrorHandler.handle(error: error, component: "WatchlistViewModel.searchStocks")
            }
            isSearching = false
        }
    }

    func deleteCategory(at offsets: IndexSet) {
        let categoriesToDelete = offsets.map { categories[$0] }
        Task {
            for category in categoriesToDelete {
                do {
                    try await APIService.shared.deleteCategory(id: category.id)
                    categories.removeAll { $0.id == category.id }
                } catch {
                    self.errorMessage = error.localizedDescription
                    ErrorHandler.handle(error: error, component: "WatchlistViewModel.deleteCategory")
                }
            }
        }
    }

    func updateCategory(category: Category, newName: String) async {
        do {
            let updatedCategory = try await APIService.shared.updateCategory(id: category.id, name: newName)
            if let index = categories.firstIndex(where: { $0.id == category.id }) {
                categories[index].name = updatedCategory.name
            }
        } catch {
            self.errorMessage = error.localizedDescription
            ErrorHandler.handle(error: error, component: "WatchlistViewModel.updateCategory")
        }
    }
}
