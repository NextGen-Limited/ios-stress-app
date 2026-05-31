import { defineConfig } from 'vitepress'

const enSidebar = {
  '/principle/': [{ text: 'Principle', items: [
    { text: 'What Type of Stress?', link: '/principle/' },
    { text: 'Stress Levels', link: '/principle/stress-levels' },
    { text: 'Stress Overload Trigger', link: '/principle/stress-overload-trigger' },
    { text: 'What is HRV?', link: '/principle/what-is-hrv' },
    { text: 'Is Higher HRV Always Better?', link: '/principle/is-higher-hrv-always-better' },
    { text: 'HRV vs Apple Health', link: '/principle/why-different-from-apple-health' },
    { text: 'Resting Heart Rate', link: '/principle/resting-heart-rate' },
    { text: 'What is Undefined?', link: '/principle/about-undefined' },
    { text: 'FAQ', link: '/principle/frequently-asked-questions' },
  ]}],
  '/user-guide/': [{ text: 'User Guide', items: [
    { text: 'Measurement Frequency', link: '/user-guide/measurement-frequency' },
    { text: 'Watch Notification Issues', link: '/user-guide/notifications-troubleshoot' },
  ]}],
  '/watch-widget/': [{ text: 'Watch & Widget', items: [
    { text: 'Watch Face Setup', link: '/watch-widget/watch-face-setup' },
    { text: 'Watch Face Not Updating', link: '/watch-widget/widget-not-updating' },
  ]}],
  '/legal/': [{ text: 'Legal', items: [
    { text: 'Privacy Policy', link: '/legal/privacy' },
    { text: 'Terms of Service', link: '/legal/terms' },
  ]}],
}

const viSidebar = {
  '/vi/principle/': [{ text: 'Nguyên lý', items: [
    { text: 'Loại căng thẳng nào?', link: '/vi/principle/' },
    { text: 'Cấp độ căng thẳng', link: '/vi/principle/stress-levels' },
    { text: 'Khi nào kích hoạt cảnh báo?', link: '/vi/principle/stress-overload-trigger' },
    { text: 'HRV là gì?', link: '/vi/principle/what-is-hrv' },
    { text: 'HRV cao hơn có luôn tốt hơn?', link: '/vi/principle/is-higher-hrv-always-better' },
    { text: 'HRV khác Apple Health?', link: '/vi/principle/why-different-from-apple-health' },
    { text: 'Nhịp tim lúc nghỉ', link: '/vi/principle/resting-heart-rate' },
    { text: 'Undefined là gì?', link: '/vi/principle/about-undefined' },
    { text: 'Câu hỏi thường gặp', link: '/vi/principle/frequently-asked-questions' },
  ]}],
  '/vi/user-guide/': [{ text: 'Hướng dẫn sử dụng', items: [
    { text: 'Tần suất đo', link: '/vi/user-guide/measurement-frequency' },
    { text: 'Sự cố thông báo', link: '/vi/user-guide/notifications-troubleshoot' },
  ]}],
  '/vi/watch-widget/': [{ text: 'Watch & Widget', items: [
    { text: 'Cài mặt đồng hồ', link: '/vi/watch-widget/watch-face-setup' },
    { text: 'Mặt đồng hồ không cập nhật', link: '/vi/watch-widget/widget-not-updating' },
  ]}],
  '/vi/legal/': [{ text: 'Pháp lý', items: [
    { text: 'Chính sách bảo mật', link: '/vi/legal/privacy' },
    { text: 'Điều khoản dịch vụ', link: '/vi/legal/terms' },
  ]}],
}

export default defineConfig({
  title: 'StressMonitor Help',
  description: 'User guide and documentation for StressMonitor',
  locales: {
    root: {
      label: 'English',
      lang: 'en',
      link: '/',
      themeConfig: {
        nav: [
          { text: 'Principle', link: '/principle/' },
          { text: 'User Guide', link: '/user-guide/' },
          { text: 'Watch & Widget', link: '/watch-widget/' },
        ],
        sidebar: enSidebar,
      },
    },
    vi: {
      label: 'Tiếng Việt',
      lang: 'vi',
      link: '/vi/',
      themeConfig: {
        nav: [
          { text: 'Nguyên lý', link: '/vi/principle/' },
          { text: 'Hướng dẫn', link: '/vi/user-guide/' },
          { text: 'Watch & Widget', link: '/vi/watch-widget/' },
        ],
        sidebar: viSidebar,
      },
    },
  },
  themeConfig: {
    footer: {
      copyright: 'Copyright © 2026 StressMonitor',
    },
  },
})
