// /Users/tony.h/tony-stock/iOS App/src/iOSApp/Sources/iOSApp/Views/WatchlistView.swift
import SwiftUI
import Charts

// MARK: - Main Watchlist View
public struct WatchlistView: View {
    @StateObject private var viewModel = WatchlistViewModel()
    @State private var showingSearch = false
    @State private var showingCategoryManager = false

    public var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.categories.isEmpty {
                Spacer()
                ProgressView(NSLocalizedString("common.loading", bundle: .module, comment: "Loading..."))
                Spacer()
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Image(systemName: "wifi.exclamationmark").font(.largeTitle).foregroundColor(.secondary)
                    Text("Error Loading Watchlist").font(.headline).padding(.top)
                    Text(errorMessage).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center).padding()
                }
            } else {
                categoryTabs
                
                if let selectedCategory = viewModel.categories.first(where: { $0.id == viewModel.selectedCategoryId }) {
                    StockListView(stocks: selectedCategory.stocks, categoryId: selectedCategory.id, viewModel: viewModel)
                } else if !viewModel.categories.isEmpty {
                     Text("Select a category", bundle: .module).foregroundColor(.secondary).frame(maxHeight: .infinity)
                } else {
                    emptyStateView
                }
            }
        }
        .navigationTitle(Text("watchlist.pageTitle", bundle: .module))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showingCategoryManager = true }) {
                    Image(systemName: "folder.badge.gearshape")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingSearch = true }) {
                    Image(systemName: "plus")
                }
                .disabled(viewModel.categories.isEmpty)
            }
        }
        .sheet(isPresented: $showingSearch) { StockSearchView(viewModel: viewModel) }
        .sheet(isPresented: $showingCategoryManager) { CategoryManagerView(viewModel: viewModel) }
        .onAppear {
            if viewModel.categories.isEmpty {
                viewModel.fetchCategories()
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(viewModel.categories) { category in
                    Button(action: { viewModel.selectedCategoryId = category.id }) {
                        Text(category.name)
                            .font(.subheadline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(viewModel.selectedCategoryId == category.id ? Color(.systemGray5) : Color.clear)
                            .clipShape(Capsule())
                    }
                    .foregroundColor(viewModel.selectedCategoryId == category.id ? .primary : .secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Spacer()
            Image(systemName: "folder.badge.plus").font(.system(size: 50)).foregroundColor(.secondary)
            Text("Create Your First Watchlist", bundle: .module).font(.title2)
            Text("Tap the '+' button to add stocks.", bundle: .module).font(.subheadline).foregroundColor(.secondary)
            Button(action: { showingCategoryManager = true }) {
                Text("Create a Category", bundle: .module)
            }
            .buttonStyle(.borderedProminent).padding(.top)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Stock List View
private struct StockListView: View {
    let stocks: [Stock]
    let categoryId: String
    @ObservedObject var viewModel: WatchlistViewModel

    var body: some View {
        List {
            ForEach(stocks) { stock in
                NavigationLink(destination: PriceAnalysisView(initialStockCode: stock.symbol, initialYears: "3.5")) {
                    StockCardView(stock: stock)
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onDelete(perform: deleteStock)
        }
        .listStyle(.plain)
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

// MARK: - Stock Card View
private struct StockCardView: View {
    let stock: Stock

    var body: some View {
        HStack(spacing: 12) {
            StockHeaderView(stock: stock)
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    Text(String(format: "$%.2f", stock.price))
                        .font(.headline.weight(.semibold))
                    Text(String(format: "%.2f%%", stock.changePercent ?? 0.0))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor((stock.changePercent ?? 0) >= 0 ? .green : .red)
                }
                
                // ✅ 錯誤修復：先註解掉需要 analysis 的視圖，待未來資料模型更新後再啟用
                /*
                if let analysis = stock.analysis {
                    PriceSentimentGauge(price: stock.price, support: analysis.tl_minus_2sd, resistance: analysis.tl_plus_2sd)
                        .frame(height: 10)
                } else {
                    Text("Analysis N/A").font(.caption).foregroundColor(.secondary)
                }
                */
            }
            .frame(width: 120)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stock Header View
private struct StockHeaderView: View {
    let stock: Stock

    var body: some View {
        HStack {
            // ✅ 錯誤修復：暫時移除 stock.logo 的使用
            Text(String(stock.symbol.prefix(1)))
                .fontWeight(.bold)
                .frame(width: 32, height: 32)
                .background(Color(.systemGray5))
                .foregroundColor(.secondary)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(stock.symbol).font(.headline)
                Text(stock.name).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
            }
        }
    }
}

// MARK: - Price Sentiment Gauge
private struct PriceSentimentGauge: View {
    let price: Double
    let support: Double
    let resistance: Double

    private var percentage: Double {
        guard resistance > support else { return 0.5 }
        let value = (price - support) / (resistance - support)
        return max(0, min(1, value))
    }
    
    var body: some View {
        // ✅ 錯誤修復：用自定義的進度條取代 unavailable 的 LinearGaugeStyle
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                Capsule()
                    .fill(sentimentColor(for: percentage))
                    .frame(width: geometry.size.width * CGFloat(percentage))
            }
        }
    }
    
    private func sentimentColor(for percentage: Double) -> Color {
        if percentage >= 0.75 { return AppColors.plus1SD }
        if percentage <= 0.25 { return AppColors.minus1SD }
        return AppColors.trend
    }
}

// ✅ 錯誤修復：將這些視圖定義加回到檔案中
// MARK: - Stock Search View
struct StockSearchView: View {
    @ObservedObject var viewModel: WatchlistViewModel
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack {
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
            .navigationTitle(Text("watchlist.addStockTitle", bundle: .module, comment: "Add Stock"))
        }
    }
}

// MARK: - Category Manager View
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
                            }.buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .onDelete(perform: viewModel.deleteCategory)
                }
                
                HStack {
                    let placeholder = NSLocalizedString("watchlist.newCategoryPlaceholder", bundle: .module, comment: "New category name")
                    TextField(placeholder, text: $newCategoryName)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: {
                        Task {
                            await viewModel.createCategory(name: newCategoryName)
                            newCategoryName = ""
                        }
                    }) {
                        Text("watchlist.addButton", bundle: .module, comment: "Add")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle(Text("watchlist.manageCategoriesTitle", bundle: .module, comment: "Manage Categories"))
            .sheet(item: $editingCategory) { category in
                EditCategoryView(viewModel: viewModel, category: category)
            }
        }
    }
}

// MARK: - Edit Category View
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
                TextField(LocalizedStringKey("watchlist.categoryNameLabel"), text: $newName)
                Button(LocalizedStringKey("watchlist.saveButton")) {
                    Task {
                        await viewModel.updateCategory(category: category, newName: newName)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle(Text("watchlist.editCategoryDialog.title", bundle: .module))
        }
    }
}