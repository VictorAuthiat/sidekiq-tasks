class TooltipsManager {
  constructor(selector = '[data-tooltip]') {
    this.selector = selector;
    this.tooltip = null;
  }

  init() {
    this.#createTooltipElement();

    document.querySelectorAll(this.selector).forEach(element => {
      element.addEventListener('mouseenter', this.#showTooltip.bind(this));
      element.addEventListener('mouseleave', this.#hideTooltip.bind(this));
    });
  }

  #createTooltipElement() {
    this.tooltip = document.createElement('div');
    this.tooltip.className = 'st-tooltip';
    document.body.appendChild(this.tooltip);
  }

  #showTooltip(event) {
    const target = event.currentTarget;
    const text = target.getAttribute('data-tooltip');

    if (!text) return;

    this.tooltip.textContent = text;
    this.tooltip.style.top = '0px';
    this.tooltip.style.left = '-9999px';
    this.tooltip.style.opacity = '1';

    requestAnimationFrame(() => {
      const rect = target.getBoundingClientRect();
      const tooltipRect = this.tooltip.getBoundingClientRect();
      const top = rect.top + window.scrollY - tooltipRect.height - 8;
      const left = rect.left + window.scrollX + rect.width / 2 - tooltipRect.width / 2;

      this.tooltip.style.top = `${top}px`;
      this.tooltip.style.left = `${left}px`;
    });
  }

  #hideTooltip() {
    this.tooltip.style.opacity = '0';
  }
}

document.addEventListener('DOMContentLoaded', () => {
  new TooltipsManager().init();
});
