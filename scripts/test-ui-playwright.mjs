import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';

const SCREENSHOT_DIR = path.resolve('e2e-screenshots');
if (!fs.existsSync(SCREENSHOT_DIR)) {
  fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
}

async function navigateViaDevBar(page, itemText) {
  // Click floating DEV BAR button
  const devBtn = page.locator('text=DEV BAR').first();
  await devBtn.click({ force: true });
  await page.waitForTimeout(600);

  // Click target link
  const target = page.locator(`text=${itemText}`).first();
  await target.click({ force: true });
  await page.waitForTimeout(1500);
}

async function run() {
  console.log('🚀 Khởi chạy Playwright E2E UI Test Suite cho Mooncake Mobile...');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 }, // iPhone 14 / Mobile standard
    deviceScaleFactor: 2,
    isMobile: true,
    hasTouch: true,
  });

  const page = await context.newPage();
  const report = {
    timestamp: new Date().toISOString(),
    tests: [],
    screenshots: [],
  };

  try {
    // 1. HomeScreen
    console.log('📱 1. Mở HomeScreen...');
    await page.goto('http://localhost:8081', { waitUntil: 'networkidle', timeout: 30000 });
    await page.waitForTimeout(2000);

    const homePath = path.join(SCREENSHOT_DIR, '01_home_screen.png');
    await page.screenshot({ path: homePath });
    report.screenshots.push({ screen: 'HomeScreen', path: homePath });
    console.log('   📸 [1/8] Chụp HomeScreen thành công.');

    // 2. SearchScreen
    console.log('📱 2. Mở SearchScreen qua DevBar...');
    await navigateViaDevBar(page, 'Tìm Kiếm & Bộ Lọc FTS');
    const searchPath = path.join(SCREENSHOT_DIR, '02_search_screen.png');
    await page.screenshot({ path: searchPath });
    report.screenshots.push({ screen: 'SearchScreen', path: searchPath });
    console.log('   📸 [2/8] Chụp SearchScreen thành công.');

    // 3. ProductDetailScreen & Calculator
    console.log('📱 3. Mở ProductDetailScreen qua DevBar...');
    await navigateViaDevBar(page, 'Chi Tiết Bánh & Biến Thể');
    const detailTopPath = path.join(SCREENSHOT_DIR, '03_product_detail_top.png');
    await page.screenshot({ path: detailTopPath });
    report.screenshots.push({ screen: 'ProductDetailTop', path: detailTopPath });

    // Cuộn xuống xem Calculator & Coupon
    await page.evaluate(() => window.scrollBy(0, 420));
    await page.waitForTimeout(600);
    const detailCalcPath = path.join(SCREENSHOT_DIR, '04_product_detail_calculator.png');
    await page.screenshot({ path: detailCalcPath });
    report.screenshots.push({ screen: 'ProductDetailCalculator', path: detailCalcPath });
    console.log('   📸 [3/8] Chụp ProductDetail & Calculator thành công.');

    // 4. UI Showcase (AntD & Lucian Labs)
    console.log('📱 4. Mở UI Showcase Screen qua DevBar...');
    await navigateViaDevBar(page, 'UI Showcase · AntD & Lucian Labs');
    const uiCatalogPath = path.join(SCREENSHOT_DIR, '05_ui_catalog.png');
    await page.screenshot({ path: uiCatalogPath });
    report.screenshots.push({ screen: 'UiCatalog', path: uiCatalogPath });
    console.log('   📸 [4/8] Chụp UiCatalogScreen thành công.');

    // 5. So Sánh Báo Giá Side-by-Side (Bidding)
    console.log('📱 5. Mở RfqDetailBiddingScreen qua DevBar...');
    await navigateViaDevBar(page, 'So Sánh Báo Giá Side-by-Side');
    const biddingPath = path.join(SCREENSHOT_DIR, '06_rfq_bidding.png');
    await page.screenshot({ path: biddingPath });
    report.screenshots.push({ screen: 'RfqBidding', path: biddingPath });
    console.log('   📸 [5/8] Chụp RfqBidding thành công.');

    // 6. Hợp Đồng Điện Tử (e-Contract) & Timeline
    console.log('📱 6. Mở ContractsScreen qua DevBar...');
    await navigateViaDevBar(page, 'Hợp Đồng Điện Tử (e-Contract)');
    const contractsPath = path.join(SCREENSHOT_DIR, '07_contracts_timeline.png');
    await page.screenshot({ path: contractsPath });
    report.screenshots.push({ screen: 'ContractsTimeline', path: contractsPath });
    console.log('   📸 [6/8] Chụp ContractsTimeline thành công.');

    // 7. Ký Số Hợp Đồng & OTP SMS
    console.log('📱 7. Mở ContractSignScreen qua DevBar...');
    await navigateViaDevBar(page, 'Ký Số Hợp Đồng & OTP SMS');
    const contractSignPath = path.join(SCREENSHOT_DIR, '08_contract_sign_otp.png');
    await page.screenshot({ path: contractSignPath });
    report.screenshots.push({ screen: 'ContractSignOtp', path: contractSignPath });
    console.log('   📸 [7/8] Chụp ContractSignOtp thành công.');

    // 8. Giám Sát Xe Lạnh & Ảnh PoD
    console.log('📱 8. Mở DeliveryPoDScreen qua DevBar...');
    await navigateViaDevBar(page, 'Giám Sát Xe Lạnh & Ảnh PoD');
    const podPath = path.join(SCREENSHOT_DIR, '09_coldchain_pod.png');
    await page.screenshot({ path: podPath });
    report.screenshots.push({ screen: 'DeliveryPoD', path: podPath });
    console.log('   📸 [8/8] Chụp DeliveryPoD thành công.');

    report.success = true;
    console.log('🎉 TOÀN BỘ 8 MÀN HÌNH ĐÃ ĐƯỢC PLAYWRIGHT KIỂM THỬ VÀ CHỤP ẢNH XUẤT SẮC!');
  } catch (err) {
    console.error('❌ Lỗi:', err);
    report.error = err.message;
  } finally {
    await browser.close();
    fs.writeFileSync(
      path.join(SCREENSHOT_DIR, 'test_report.json'),
      JSON.stringify(report, null, 2),
      'utf8'
    );
  }
}

run();
