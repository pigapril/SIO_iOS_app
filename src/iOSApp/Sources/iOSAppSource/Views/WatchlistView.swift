// /Users/tony.h/tony-stock/iOS App/src/iOSApp/Sources/iOSApp/Views/WatchlistView.swift
import SwiftUI
import Charts

// MARK: - Main Watchlist View
public struct WatchlistView: View {
    @StateObject private var viewModel = WatchlistViewModel()
    @State private var showingSearch = false
    @State private var showingCategoryManager = false
    @EnvironmentObject private var toastManager: ToastManager
    @EnvironmentObject private var authViewModel: AuthenticationViewModel


    public init() {}

    public var body: some View {
        // --- MODIFICATION START ---
        // Check authentication status first.
        if !authViewModel.isAuthenticated {
            loginPromptView
        } else {
            // Original content for authenticated users.
            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.categories.isEmpty {
                    Spacer()
                    ProgressView {
                        Text("common.loading", bundle: .module)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    errorStateView(message: errorMessage)
                } else if viewModel.categories.isEmpty {
                    emptyStateView
                } else {
                    categoryTabs
                    StockListView(
                        stocks: viewModel.categories.first { $0.id == viewModel.selectedCategoryId }?.stocks ?? [],
                        categoryId: viewModel.selectedCategoryId,
                        viewModel: viewModel,
                        showingSearch: $showingSearch
                    )
                }
            }
            .navigationTitle(Text("watchlist.pageTitle", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingCategoryManager = true }) {
                        Label(LocalizedStringKey("watchlist.categoryTabs.manageCategoriesAria"), systemImage: "folder.badge.gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSearch = true }) {
                        Label(LocalizedStringKey("watchlist.stock.addTitle"), systemImage: "plus")
                    }
                    .disabled(viewModel.categories.isEmpty)
                }
            }
            .sheet(isPresented: $showingSearch) {
                 StockSearchView(viewModel: viewModel)
                    .toast(toast: $toastManager.toast)
                    .environmentObject(toastManager)
            }
            .sheet(isPresented: $showingCategoryManager) {
                 CategoryManagerView(viewModel: viewModel)
                    .toast(toast: $toastManager.toast)
                    .environmentObject(toastManager)
            }
            .onAppear {
                if authViewModel.isAuthenticated && viewModel.categories.isEmpty {
                    viewModel.fetchCategories()
                }
            }
            .background(Color(.systemGroupedBackground))
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("錯誤"),
                    message: Text(viewModel.alertMessage ?? "發生未知錯誤"),
                    dismissButton: .default(Text("確定")) {
                        viewModel.alertMessage = nil
                    }
                )
            }
        }
        // --- MODIFICATION END ---
    }
    
    // --- NEW SUBVIEW ---
    /// A view to prompt the user to log in to use the watchlist feature.
    private var loginPromptView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("watchlist.loginRequiredMessage", bundle: .module)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("watchlist.loginPrompt.message", bundle: .module)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                Task {
                    await authViewModel.signIn()
                }
            }) {
                Text("userActions.login", bundle: .module)
                    .fontWeight(.bold)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
            
            Spacer()
            Spacer()
        }
        .padding()
        .navigationTitle(Text("watchlist.pageTitle", bundle: .module))
    }
    // --- END NEW SUBVIEW ---
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(viewModel.categories) { category in
                    Button(action: { viewModel.selectedCategoryId = category.id }) {
                        Text(category.name)
                            .font(.subheadline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(viewModel.selectedCategoryId == category.id ? Color.blue.opacity(0.15) : Color.clear)
                            .clipShape(Capsule())
                    }
                    .foregroundColor(viewModel.selectedCategoryId == category.id ? .blue : .primary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    private func errorStateView(message: String) -> some View {
         VStack {
             Spacer()
             Image(systemName: "wifi.exclamationmark").font(.largeTitle).foregroundColor(.secondary)
             Text("watchlist.error.title", bundle: .module).font(.headline).padding(.top)
             Text(message).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center).padding()
             Button(action: {
                 viewModel.fetchCategories()
             }) {
                Text("errorBoundary.retryButton", bundle: .module)
             }
             .buttonStyle(.bordered)
             Spacer()
         }
         .padding()
     }
    
    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Spacer()
            Image(systemName: "folder.badge.plus").font(.system(size: 50)).foregroundColor(.secondary)
            Text("watchlist.category.noCategory", bundle: .module).font(.title2)
            Text("watchlist.category.noCategoryMessage", bundle: .module).font(.subheadline).foregroundColor(.secondary)
            Button(action: { showingCategoryManager = true }) {
                Label(LocalizedStringKey("watchlist.categoryTabs.manageCategoriesAria"), systemImage: "folder.badge.gearshape")
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
    let categoryId: String?
    @ObservedObject var viewModel: WatchlistViewModel
    @Binding var showingSearch: Bool

    var body: some View {
        List {
            if stocks.isEmpty {
                 VStack(spacing: 15) {
                     Spacer()
                     Image(systemName: "chart.bar.fill").font(.system(size: 50)).foregroundColor(.secondary)
                     Text("watchlist.category.emptyTitle", bundle: .module).font(.title2)
                     Text("watchlist.category.emptyMessage", bundle: .module).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                     Button(action: { showingSearch = true }) {
                         HStack {
                             Image(systemName: "plus.circle.fill")
                             Text(NSLocalizedString("watchlist.stock.addTitle", bundle: .module, comment: "用於在股票列表中添加股票按鈕的標題"))
                         }
                         .frame(maxWidth: .infinity, alignment: .center)
                     }
                     .buttonStyle(.borderedProminent).padding(.top)
                     Spacer()
                 }
                 .frame(maxWidth: .infinity, minHeight: 200)
                 .listRowSeparator(.hidden)
            } else {
                 ForEach(stocks) { stock in
                     NavigationLink(destination: PriceAnalysisView(initialStockCode: stock.symbol, initialYears: "3.5")) {
                         StockCardView(stock: stock)
                     }
                     .buttonStyle(PlainButtonStyle())
                     .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                 }
                 .onDelete(perform: deleteStock)
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.fetchCategories()
        }
    }
    
    private func deleteStock(at offsets: IndexSet) {
        guard let categoryId = categoryId else { return }
        viewModel.removeStock(from: categoryId, at: offsets)
    }
}

// MARK: - Stock Card View
private struct StockCardView: View {
    let stock: Stock

    var body: some View {
        HStack(spacing: 12) {
            StockHeaderView(stock: stock)
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", stock.price))
                    .font(.headline.weight(.semibold))
                
                if stock.analysis != nil {
                    PriceSentimentGauge(stock: stock)
                        .frame(height: 20)
                } else {
                    HStack {
                        ProgressView().scaleEffect(0.7)
                        Text(LocalizedStringKey("watchlist.stockCard.analysis.loading"), bundle: .module)
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
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
            AsyncImage(url: URL(string: stock.logo ?? "")) { image in
                 image.resizable().aspectRatio(contentMode: .fit)
             } placeholder: {
                 Text(String(stock.symbol.prefix(1)))
                     .fontWeight(.bold)
                     .foregroundColor(.secondary)
             }
            .frame(width: 40, height: 40)
            .background(Color(.systemGray6))
            .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(stock.symbol).font(.headline)
                Text(stock.name).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
            }
        }
    }
}

// MARK: - Price Sentiment Gauge and Label (CORRECTED)
private struct PriceSentimentGauge: View {
    let stock: Stock

    // Calculate percentage position of price between support and resistance
    private var percentage: Double {
        guard let analysis = stock.analysis else { return 0.5 }
        let support = analysis.tl_minus_2sd
        let resistance = analysis.tl_plus_2sd
        guard resistance > support else { return 0.5 }
        let value = (stock.price - support) / (resistance - support)
        return max(0, min(1, value)) // Clamp between 0 and 1
    }
    
    // Determine sentiment key based on position
    private var sentimentKey: String {
        guard let analysis = stock.analysis else { return "priceAnalysis.sentiment.neutral" }
        if stock.price >= analysis.tl_plus_2sd { return "priceAnalysis.sentiment.extremeOptimism" }
        if stock.price > analysis.tl_plus_sd { return "priceAnalysis.sentiment.optimism" }
        if stock.price <= analysis.tl_minus_2sd { return "priceAnalysis.sentiment.extremePessimism" }
        if stock.price < analysis.tl_minus_sd { return "priceAnalysis.sentiment.pessimism" }
        return "priceAnalysis.sentiment.neutral"
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(LocalizedStringKey(sentimentKey), bundle: .module)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(sentimentColor)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(sentimentColor.opacity(0.7))
                        .frame(width: geometry.size.width * CGFloat(percentage))
                    Circle()
                        .fill(.white)
                        .frame(width: 8, height: 8)
                        .shadow(radius: 1)
                        .offset(x: geometry.size.width * CGFloat(percentage) - 4)
                }
            }
            .frame(height: 8)
        }
    }
    
    // Determine color based on sentiment key
    private var sentimentColor: Color {
        switch sentimentKey {
            case "priceAnalysis.sentiment.extremeOptimism": return AppColors.plus2SD
            case "priceAnalysis.sentiment.optimism": return AppColors.plus1SD
            case "priceAnalysis.sentiment.pessimism": return AppColors.minus1SD
            case "priceAnalysis.sentiment.extremePessimism": return AppColors.minus2SD
            default: return AppColors.trend
        }
    }
}

// MARK: - Stock Search View
struct StockSearchView: View {
    @ObservedObject var viewModel: WatchlistViewModel
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                List(viewModel.searchResults) { result in
                    Button(action: {
                        Task {
                            await viewModel.addStock(symbol: result.symbol)
                            dismiss()
                        }
                    }) {
                        VStack(alignment: .leading) {
                            Text(result.symbol).font(.headline)
                            Text(result.name).font(.subheadline).foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
                .overlay {
                    if viewModel.isSearching && viewModel.searchResults.isEmpty {
                        ProgressView()
                    }
                }
            }
            .searchable(text: $searchText, prompt: Text("watchlist.searchBox.placeholder", bundle: .module))
            .onChange(of: searchText) { newValue in
                viewModel.searchStocks(keyword: newValue)
            }
            .navigationTitle(Text("watchlist.stock.addTitle", bundle: .module))
            .navigationBarItems(trailing: Button(action: { dismiss() }) {
                Text("common.done", bundle: .module)
            })
        }
    }
}

// MARK: - Category Manager View
struct CategoryManagerView: View {
    @ObservedObject var viewModel: WatchlistViewModel
    @State private var newCategoryName = ""
    @State private var editingCategory: Category?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var toastManager: ToastManager


    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section{
                        ForEach(viewModel.categories) { category in
                            HStack {
                                Text(category.name)
                                Spacer()
                                Button(action: { editingCategory = category }) {
                                    Image(systemName: "pencil.line")
                                }.buttonStyle(BorderlessButtonStyle())
                            }

                        }
                        .onDelete(perform: viewModel.deleteCategory)
                    }
                }
                .listStyle(.insetGrouped)
                
                HStack {
                    // --- FINAL FIX: Use NSLocalizedString for TextField placeholder ---
                    TextField(
                        NSLocalizedString("watchlist.createCategoryDialog.placeholder", bundle: .module, comment: ""),
                        text: $newCategoryName
                    )
                    .textFieldStyle(.roundedBorder)
                    
                    Button(action: {
                        Task {
                            await viewModel.createCategory(name: newCategoryName)
                            newCategoryName = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.borderless)
                    .disabled(newCategoryName.isEmpty)
                }
                .padding()
            }
            .navigationTitle(Text("watchlist.categoryTabs.manageCategoriesAria", bundle: .module))
            .navigationBarItems(leading: EditButton(), trailing: Button(action: { dismiss() }) {
                Text(NSLocalizedString("common.done", bundle: .module, comment: "Done button for category manager"))
            })
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
    @Environment(\.dismiss) var dismiss

    init(viewModel: WatchlistViewModel, category: Category) {
        self.viewModel = viewModel
        self.category = category
        _newName = State(initialValue: category.name)
    }

    var body: some View {
        NavigationView {
            Form {
                // --- FINAL FIX: Use NSLocalizedString for TextField placeholder ---
                TextField(
                    NSLocalizedString("watchlist.editCategoryDialog.placeholder", bundle: .module, comment: ""),
                    text: $newName
                )
                
                Button(action: {
                    Task {
                        await viewModel.updateCategory(category: category, newName: newName)
                        dismiss()
                    }
                }) {
                    Text("watchlist.editCategoryDialog.confirmButton", bundle: .module)
                }
            }
            .navigationTitle(Text("watchlist.editCategoryDialog.title", bundle: .module))
            .navigationBarItems(trailing: Button(action: { dismiss() }) {
                Text(NSLocalizedString("common.cancel", bundle: .module, comment: "Cancel button for edit category"))
            })
        }
    }
}