import SwiftUI

// MARK: - 主視圖 (WatchlistView)
struct WatchlistView: View {
    @StateObject private var viewModel = WatchlistViewModel()
    @State private var showingSearch = false
    @State private var showingCategoryManager = false

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                // 錯誤訊息通常來自後端，不進行本地化，或由 ViewModel 處理
                Text(errorMessage)
            } else {
                if #available(iOS 16.0, *) {
                    TabView(selection: $viewModel.selectedCategoryId) {
                        ForEach(viewModel.categories) { category in
                            StockListView(stocks: category.stocks, categoryId: category.id, viewModel: viewModel)
                                .tabItem {
                                    Text(category.name)
                                }
                                .tag(category.id)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                } else {
                    // 舊版 iOS 的備用方案
                    Picker("Category", selection: $viewModel.selectedCategoryId) {
                        ForEach(viewModel.categories) { category in
                            Text(category.name).tag(category.id)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if let selectedCategory = viewModel.categories.first(where: { $0.id == viewModel.selectedCategoryId }) {
                        StockListView(stocks: selectedCategory.stocks, categoryId: selectedCategory.id, viewModel: viewModel)
                    }
                }
            }
        }
        // 使用翻譯鍵
        .navigationTitle(Text("watchlist.pageTitle", bundle: .module))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showingCategoryManager = true }) {
                    Image(systemName: "folder.badge.plus")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingSearch = true }) {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .sheet(isPresented: $showingSearch) {
            StockSearchView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingCategoryManager) {
            CategoryManagerView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.fetchCategories()
        }
    }
}

// MARK: - 股票列表 (StockListView)
struct StockListView: View {
    let stocks: [Stock]
    let categoryId: Int
    @ObservedObject var viewModel: WatchlistViewModel

    var body: some View {
        List {
            ForEach(stocks) { stock in
                StockRow(stock: stock)
            }
            .onDelete(perform: deleteStock)
        }
    }
    
    private func deleteStock(at offsets: IndexSet) {
        let stocksToDelete = offsets.map { stocks[$0] }
        Task {
            for stock in stocksToDelete {
                await viewModel.removeStock(categoryId: categoryId, itemId: stock.id)
            }
        }
    }
}

// MARK: - 股票行 (StockRow)
struct StockRow: View {
    let stock: Stock
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(stock.symbol).font(.headline)
                Text(stock.name).font(.subheadline)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(String(format: "%.2f", stock.lastPrice))
                Text(String(format: "%.2f (%.2f%%)", stock.change, stock.changePercent))
                    .foregroundColor(stock.change >= 0 ? .green : .red)
            }
        }
    }
}

// MARK: - 股票搜尋視圖 (StockSearchView)
struct StockSearchView: View {
    @ObservedObject var viewModel: WatchlistViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                // 使用翻譯鍵
                let placeholder = NSLocalizedString("watchlist.searchBox.placeholder", bundle: .module, comment: "Search stocks...")
                TextField(placeholder, text: $searchText)
                    .padding()
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: searchText) { newValue in
                        viewModel.searchStocks(keyword: newValue)
                    }
                
                List(viewModel.searchResults) { result in
                    Button(action: {
                        Task {
                            await viewModel.addStock(symbol: result.symbol)
                        }
                    }) {
                        Text("\(result.symbol) - \(result.name)")
                    }
                }
            }
            // 使用翻譯鍵
            .navigationTitle(Text("watchlist.addStockTitle", bundle: .module))
        }
    }
}

// MARK: - 分類管理視圖 (CategoryManagerView)
struct CategoryManagerView: View {
    @ObservedObject var viewModel: WatchlistViewModel
    @State private var newCategoryName = ""
    @State private var editingCategory: Category?

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(viewModel.categories) { category in
                        HStack {
                            Text(category.name)
                            Spacer()
                            Button(action: { editingCategory = category }) {
                                Image(systemName: "pencil")
                            }
                        }
                    }
                    .onDelete(perform: viewModel.deleteCategory)
                }
                
                HStack {
                    // 使用翻譯鍵
                    let placeholder = NSLocalizedString("watchlist.newCategoryPlaceholder", bundle: .module, comment: "New category name")
                    TextField(placeholder, text: $newCategoryName)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: {
                        Task {
                            await viewModel.createCategory(name: newCategoryName)
                            newCategoryName = ""
                        }
                    }) {
                        // 使用翻譯鍵
                        Text("watchlist.addButton", bundle: .module)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            // 使用翻譯鍵
            .navigationTitle(Text("watchlist.manageCategoriesTitle", bundle: .module))
            .sheet(item: $editingCategory) { category in
                EditCategoryView(viewModel: viewModel, category: category)
            }
        }
    }
}

// MARK: - 編輯分類視圖 (EditCategoryView)
struct EditCategoryView: View {
    @ObservedObject var viewModel: WatchlistViewModel
    let category: Category
    @State private var newName: String
    @Environment(\.presentationMode) var presentationMode

    init(viewModel: WatchlistViewModel, category: Category) {
        self.viewModel = viewModel
        self.category = category
        _newName = State(initialValue: category.name)
    }

    var body: some View {
        NavigationView {
            Form {
                // 使用翻譯鍵
                TextField(LocalizedStringKey("watchlist.categoryNameLabel"), text: $newName)
                Button(LocalizedStringKey("watchlist.saveButton")) {
                    Task {
                        await viewModel.updateCategory(category: category, newName: newName)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            // 使用翻譯鍵
            .navigationTitle(Text("watchlist.editCategoryDialog.title", bundle: .module))
        }
    }
}
