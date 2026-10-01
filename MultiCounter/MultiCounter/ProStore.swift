//
//  ProStore.swift
//  MultiCounter
//
//  Pro 일회성 구매(비소모성 상품) 처리
//

import StoreKit

@Observable
@MainActor
final class ProStore {
  static let shared = ProStore()

  static let productID = "com.chaechae.count.pro"
  /// Pro가 처음 들어가는 빌드 번호(CFBundleVersion).
  /// 이보다 낮은 빌드로 처음 설치한 사용자는 기존 10개 카운터를 유지
  static let firstProBuild = 2

  private(set) var product: Product?
  private(set) var isPurchasing = false

  private var updatesTask: Task<Void, Never>?

  private init() {}

  func start() {
    guard updatesTask == nil else { return }
    // 다른 기기에서 구매·환불한 내역도 반영
    updatesTask = Task {
      for await result in Transaction.updates {
        if case .verified(let transaction) = result {
          await transaction.finish()
          await refreshEntitlement()
        }
      }
    }
    // 상품 정보(가격)를 못 불러와도 구매 여부 확인은 먼저 끝나야 하므로 따로 실행
    Task {
      await refreshEntitlement()
      await checkLegacyUser()
    }
    Task {
      await loadProduct()
    }
  }

  func loadProduct() async {
    product = try? await Product.products(for: [Self.productID]).first
  }

  func refreshEntitlement() async {
    #if DEBUG
    // 시뮬레이터에서 Pro 기능을 확인할 때: 실행 인자 -ForcePro YES
    // (App Store 계정이 없는 시뮬레이터에서는 구매 내역 조회가 끝나지 않으므로 먼저 처리)
    if UserDefaults.standard.bool(forKey: "ForcePro") {
      CounterStore.shared.setPro(true)
      return
    }
    #endif
    var owned = false
    for await result in Transaction.currentEntitlements {
      if case .verified(let transaction) = result,
         transaction.productID == Self.productID,
         transaction.revocationDate == nil {
        owned = true
      }
    }
    CounterStore.shared.setPro(owned)
  }

  func purchase() async {
    if product == nil { await loadProduct() }
    guard let product, !isPurchasing else { return }
    isPurchasing = true
    defer { isPurchasing = false }

    guard let result = try? await product.purchase() else { return }
    if case .success(.verified(let transaction)) = result {
      await transaction.finish()
      await refreshEntitlement()
    }
  }

  func restore() async {
    try? await AppStore.sync()
    await refreshEntitlement()
  }

  /// 저장된 데이터가 없어도 예전 버전으로 처음 설치한 사용자라면 기존 사용자로 인정
  /// 결과를 한 번 확인하면 다시 묻지 않음 (App Store 로그인이 안 된 기기에서 매번 로그인 창이 뜨지 않도록)
  private func checkLegacyUser() async {
    let checkedKey = "LegacyUserChecked"
    guard !SharedStorage.isLegacyUser,
          !UserDefaults.standard.bool(forKey: checkedKey),
          let result = try? await AppTransaction.shared,
          case .verified(let appTransaction) = result else { return }
    UserDefaults.standard.set(true, forKey: checkedKey)
    if let originalBuild = Int(appTransaction.originalAppVersion),
       originalBuild < Self.firstProBuild {
      CounterStore.shared.markLegacyUser()
    }
  }
}
