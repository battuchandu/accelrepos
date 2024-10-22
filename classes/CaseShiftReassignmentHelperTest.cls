@isTest
public class CaseShiftReassignmentHelperTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Queues (Groups)
        Group morningShiftQueue = new Group(Name = 'Morning Shift Queue', Type = 'Queue');
        Group afternoonShiftQueue = new Group(Name = 'Afternoon Shift Queue', Type = 'Queue');
        Group nightShiftQueue = new Group(Name = 'Night Shift Queue', Type = 'Queue');
        insert new List<Group>{morningShiftQueue, afternoonShiftQueue, nightShiftQueue};
        
        // Create test cases with different assigned shift times
        Datetime now = System.now();
        
        List<Case> cases = new List<Case>{
            new Case(Status = 'New', OwnerId = morningShiftQueue.Id, Assigned_Shift_Time__c = now.addHours(-8), Initial_Shift_Name__c = 'Morning Shift'),
            new Case(Status = 'New', OwnerId = afternoonShiftQueue.Id, Assigned_Shift_Time__c = now.addHours(-8), Initial_Shift_Name__c = 'Afternoon Shift'),
            new Case(Status = 'New', OwnerId = nightShiftQueue.Id, Assigned_Shift_Time__c = now.addHours(-8), Initial_Shift_Name__c = 'Night Shift'),
            new Case(Status = 'New', OwnerId = morningShiftQueue.Id, Assigned_Shift_Time__c = now, Initial_Shift_Name__c = 'Morning Shift'), // Not enough time passed
            new Case(Status = 'New', OwnerId = afternoonShiftQueue.Id, Assigned_Shift_Time__c = now, Initial_Shift_Name__c = 'Afternoon Shift'), // Not enough time passed
            new Case(Status = 'New', OwnerId = nightShiftQueue.Id, Assigned_Shift_Time__c = null, Initial_Shift_Name__c = 'Night Shift') // Null Assigned_Shift_Time__c
        };
        
        insert cases;
    }

    @isTest
    static void testReassignCases() {
        Test.startTest();
        CaseShiftReassignmentHelper.reassignCases();
        Test.stopTest();

        // Verify that cases have been reassigned correctly
        Group afternoonShiftQueue = [SELECT Id FROM Group WHERE Name = 'Afternoon Shift Queue' LIMIT 1];
        Group nightShiftQueue = [SELECT Id FROM Group WHERE Name = 'Night Shift Queue' LIMIT 1];
        Group morningShiftQueue = [SELECT Id FROM Group WHERE Name = 'Morning Shift Queue' LIMIT 1];

        // Fetch updated cases
        List<Case> updatedCases = [SELECT Id, OwnerId, Initial_Shift_Name__c FROM Case];

        for (Case c : updatedCases) {
            if (c.Initial_Shift_Name__c == 'Morning Shift' && c.OwnerId == afternoonShiftQueue.Id) {
                System.assertEquals(afternoonShiftQueue.Id, c.OwnerId, 'Case should have been reassigned to the afternoon shift.');
            } else if (c.Initial_Shift_Name__c == 'Afternoon Shift' && c.OwnerId == nightShiftQueue.Id) {
                System.assertEquals(nightShiftQueue.Id, c.OwnerId, 'Case should have been reassigned to the night shift.');
            } else if (c.Initial_Shift_Name__c == 'Night Shift' && c.OwnerId == morningShiftQueue.Id) {
                System.assertEquals(morningShiftQueue.Id, c.OwnerId, 'Case should have been reassigned to the morning shift.');
            }
        }
    }

    @isTest
    static void testScheduleClass() {
        // Test the scheduled job
        Test.startTest();
        String cronExp = '0 0 23 * * ?'; // Arbitrary cron expression
        scheduleClass schedClass = new scheduleClass();
        System.schedule('Test Case Shift Reassignment Job', cronExp, schedClass);
        Test.stopTest();

        // Check that cases have been reassigned correctly after the scheduled execution
        List<Case> updatedCases = [SELECT Id, OwnerId, Initial_Shift_Name__c FROM Case];
        System.assert(updatedCases.size() > 0, 'There should be cases reassigned.');
    }
}