import { $ } from "@wdio/globals";
import Page from "./page.js";

/**
 * sub page containing specific selectors and methods for a specific page
 */
class LoginPage extends Page {
  /**
   * define selectors using getter methods
   */
  get inputEmail() {
    return $("#email-input");
  }

  get inputPassword() {
    return $("#password-input");
  }

  get btnSubmit() {
    return $('button[type="submit"]');
  }

  get dinumOrgTile() {
    return $("a*=DINUM");
  }

  /**
   * a method to encapsule automation code to interact with the page
   * e.g. to login using username and password
   */
  async login(email, password) {
    await this.inputEmail.setValue(email);
    await this.btnSubmit.click();
    await this.inputPassword.setValue(password);
    await this.btnSubmit.click();
    await this.dinumOrgTile.click();
  }

  /**
   * overwrite specific options to adapt it to page object
   */
  open() {
    return super.open("/o/docs/login?next=/");
  }
}

export default new LoginPage();
