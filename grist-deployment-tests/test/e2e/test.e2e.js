import { expect } from '@wdio/globals'
import LoginPage from '../pageobjects/login.page.js'
import HomePage from '../pageobjects/homepage.page.js'
import assert from 'assert';

describe('Login', () => {
  it('should login and logout with valid credentials using ProConnect OIDC Identity Provider', async () => {
    // Given
    await HomePage.open();
    if (await HomePage.userAgreementPopup.isDisplayed()) {
      await HomePage.acceptUserAgreements();
    }
    await HomePage.goToLogin();

    // When
    await LoginPage.login('user@yopmail.com', 'user@yopmail.com')

    // Then
    await expect(HomePage.userIcon).toBeDisplayed();
    await expect(HomePage.loginBtn).not.toBeDisplayed();
    
    // When
    await HomePage.logout();

    // Then
    await expect(HomePage.userIcon).not.toBeDisplayed();
    await expect(HomePage.loginBtn).toBeDisplayed();
  });
});

