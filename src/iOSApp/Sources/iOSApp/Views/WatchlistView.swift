import SwiftUI

struct WatchlistView: View {
    @StateObject private var viewModel = WatchlistViewModel()
    @State private var showingSearch = false
    @State private var showingCategoryManager = false

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            } else {
                if #available(iOS 16.0, *) {
                    TabView(selection: $viewModel.selectedCategoryId) {
                        ForEach(viewModel.categories) { category in
                            StockListView(stocks: category.stocks)
                                .tabItem {
                                    Text(category.name)
                                }
                                .tag(category.id)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                } else {
                    // Fallback on earlier versions
                }
            }
        }
        .navigationTitle("觀察清單")
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

struct StockListView: View {
    let stocks: [Stock]

    var body: some View {
        List(stocks) { stock in
            StockRow(stock: stock)
        }
    }
}

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

struct StockSearchView: View {
    @ObservedObject var viewModel: WatchlistViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
                TextField("搜尋股票...", text: $searchText)
                    .padding()
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
            .navigationTitle("新增股票")
        }
    }
}

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
                    TextField("新分類名稱", text: $newCategoryName)
                    Button(action: {
                        Task {
                            await viewModel.createCategory(name: newCategoryName)
                            newCategoryName = ""
                        }
                    }) {
                        Text("新增")
                    }
                }
                .padding()
            }
            .navigationTitle("管理分類")
            .sheet(item: $editingCategory) { category in
                EditCategoryView(viewModel: viewModel, category: category)
            }
        }
    }
}

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
                TextField("分類名稱", text: $newName)
                Button("儲存") {
                    Task {
                        await viewModel.updateCategory(category: category, newName: newName)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("編輯分類")
        }
    }
} 