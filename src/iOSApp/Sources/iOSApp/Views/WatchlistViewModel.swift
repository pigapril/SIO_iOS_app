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
        if let category = categories.first(where: { $0.id == categoryId }), category.stocks.contains(where: { $0.symbol == symbol }) {
            self.errorMessage = "\(symbol) is already in this category."
            return
        }

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
    
    func removeStock(from categoryId: String, at offsets: IndexSet) {
        guard let categoryIndex = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        
        let stocksToDelete = offsets.map { categories[categoryIndex].stocks[$0] }
        
        Task {
            for stock in stocksToDelete {
                do {
                    try await APIService.shared.removeStock(categoryId: categoryId, itemId: stock.id)
                    // On success, remove from local array
                    if let stockIndex = self.categories[categoryIndex].stocks.firstIndex(where: { $0.id == stock.id }) {
                        self.categories[categoryIndex].stocks.remove(at: stockIndex)
                    }
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
                    // If the deleted category was the selected one, select another one
                    if selectedCategoryId == category.id {
                        selectedCategoryId = categories.first?.id
                    }
                } catch {
                    self.errorMessage = error.localizedDescription
                    ErrorHandler.handle(error: error, component: "WatchlistViewModel.deleteCategory")
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
            self.errorMessage = error.localizedDescription
            ErrorHandler.handle(error: error, component: "WatchlistViewModel.updateCategory")
        }
    }
}