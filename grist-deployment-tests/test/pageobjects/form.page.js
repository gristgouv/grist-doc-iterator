import { $ } from "@wdio/globals";
import Page from "./page.js";

class FormPage extends Page {
  get genericErrorMessage() {
    return $("div*=error submitting");
  }

  get successMessage() {
    return $(".test-form-success-page-text");
  }

  get submitButton() {
    return $('button[type="submit"]');
  }

  async selectFileForField(fieldName, fixture) {
    return $(`input[type="file"][name=${fieldName}`).setValue(fixture);
  }

  async submit() {
    return this.submitButton.click();
  }
}

export default new FormPage();
