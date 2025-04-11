import { $ } from "@wdio/globals";
import Page from "./page.js";

/**
 * sub page containing specific selectors and methods for a specific page
 */
class HomePage extends Page {
  /**
   * define selectors using getter methods
   */
  get loginBtn() {
    return $(".test-user-sign-in");
  }

  get userIcon() {
    return $(".test-user-icon");
  }

  get logoutMenu() {
    return $(".test-dm-log-out");
  }

  get maintenancePopin() {
    return $("#maintenancePopin");
  }

  get acknowledgeMaintenanceCheckbox() {
    return $("#jaiCompris");
  }

  get closeMaintenancePopinBtn() {
    return $("#fermerPopinMaintenance");
  }

  open() {
    return super.open("/");
  }

  async goToLogin() {
    await this.loginBtn.click();
  }

  async logout() {
    await this.userIcon.click();
    await this.logoutMenu.click();
  }

  async acknowledgeMaintenance() {
    await this.acknowledgeMaintenanceCheckbox.click();
    await this.closeMaintenancePopinBtn.click();
  }
}

export default new HomePage();
