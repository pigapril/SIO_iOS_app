import SwiftUI
import Combine

@MainActor
class WatchlistViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var selectedCategoryId: Int?
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
                if let firstCategory = fetchedCategories.first {
                    self.selectedCategoryId = firstCategory.id
                }
            } catch {
                self.errorMessage = error.localizedDescription
                ErrorHandler.handle(error: error, component: "WatchlistViewModel")
            }
            self.isLoading = false
        }
    }
    
    // Add other methods for creating/deleting categories and stocks
    func createCategory(name: String) async {
        do {
            let newCategory = try await APIService.shared.createCategory(name: name)
            categories.append(newCategory)
        } catch {
            // ... error handling
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
            // ... error handling
        }
    }
    
    func searchStocks(keyword: String) {
        isSearching = true
        Task {
            do {
                self.searchResults = try await APIService.shared.searchStocks(keyword: keyword)
            } catch {
                // ... error handling
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
                    // ... error handling
                }
            }
        }
    }

    func updateCategory(category: Category, newName: String) async {
        do {
            var updatedCategory = try await APIService.shared.updateCategory(id: category.id, name: newName)
            if let index = categories.firstIndex(where: { $0.id == category.id }) {
                categories[index].name = updatedCategory.name
            }
        } catch {
            // ... error handling
        }
    }
} 