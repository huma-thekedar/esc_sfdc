@isTest
private class ESC_NBC_UserControllerTest {

    @isTest
    static void testGetUserProfileName() {
        // Get the running user's profile name
        String profileName = ESC_NBC_UserController.getUserProfileName();

        System.assertNotEquals(null, profileName, 'Profile name should not be null');
        System.debug('User profile name: ' + profileName);
    }
}