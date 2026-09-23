'use strict';
const preview = document.querySelector('#app-preview');
const appearanceButtons = document.querySelectorAll('[data-appearance]');
if (preview) {
  appearanceButtons.forEach((button) => {
    button.addEventListener('click', () => {
      const appearance = button.dataset.appearance;
      const english = document.documentElement.lang === 'en';
      preview.src = preview.dataset[appearance];
      preview.alt = english
        ? `ChatGPT Proxy Launcher in ${appearance} appearance: proxy settings, launch controls and connection checks`
        : `ChatGPT Proxy Launcher ${appearance === 'dark' ? '深色' : '浅色'}界面：代理设置、启动控制与连接检查`;
      preview.closest('a').href = preview.src;
      appearanceButtons.forEach((item) => item.setAttribute('aria-pressed', String(item === button)));
    });
  });
}
