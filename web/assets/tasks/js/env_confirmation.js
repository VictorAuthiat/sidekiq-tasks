class EnvConfirmation {
  constructor(envConfirmationInputSelector, submitBtnSelector) {
    this.envConfirmationInput = document.querySelector(envConfirmationInputSelector);
    this.submitBtn = document.querySelector(submitBtnSelector);
  }

  init() {
    this.submitBtn.disabled = true;
    this.currentEnv = this.envConfirmationInput.dataset.currentEnv;
    this.envConfirmationInput.addEventListener("input", this.#handleInputChange.bind(this));
  }

  #handleInputChange() {
    this.submitBtn.disabled = this.envConfirmationInput.value !== this.currentEnv;
  }
}

document.addEventListener("DOMContentLoaded", function() {
  new EnvConfirmation("#envConfirmationInput", "#submitBtn").init();
});
