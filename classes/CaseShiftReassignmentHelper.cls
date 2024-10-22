public class CaseShiftReassignmentHelper {
    
    // Method to reassign cases based on 7-hour inactivity
    public static void reassignCases() {
        // Queue IDs for different shifts
        Id morningShiftQueue = '00GJ100000121iIMAQ';
        Id afternoonShiftQueue = '00GJ100000121i3MAA';
        Id nightShiftQueue = '00GJ100000121iNMAQ';

        // Query cases that have not been opened yet and are assigned to a shift
        List<Case> casesToReassign = [
            SELECT Id, OwnerId, CreatedDate, Assigned_Shift_Time__c, Initial_Shift_Name__c
            FROM Case 
            WHERE Status = 'New'  
            AND (OwnerId = :morningShiftQueue OR OwnerId = :afternoonShiftQueue OR OwnerId = :nightShiftQueue)
        ];

        List<Case> casesToUpdate = new List<Case>();

        for (Case c : casesToReassign) {
            if (c.Assigned_Shift_Time__c == null) {
                System.debug('Skipping case due to null Assigned_Shift_Time__c: ' + c.Id);
                continue; // Skip if the assigned time is null
            }

            Datetime assignedTime = c.Assigned_Shift_Time__c;
            Datetime currentTime = System.now();
            Long hoursSinceAssigned = (currentTime.getTime() - assignedTime.getTime()) / (1000 * 60 * 60); // Difference in hours

            System.debug('Case ID: ' + c.Id + ', OwnerId: ' + c.OwnerId + ', Hours Since Assigned: ' + hoursSinceAssigned);

            if (hoursSinceAssigned >= 7) {
                if (c.OwnerId == morningShiftQueue) {
                    // Reassign to afternoon shift
                    c.OwnerId = afternoonShiftQueue;
                    c.Initial_Shift_Name__c = 'Morning Shift';
                } else if (c.OwnerId == afternoonShiftQueue) {
                    // Reassign to night shift
                    c.OwnerId = nightShiftQueue;
                    c.Initial_Shift_Name__c = 'Afternoon Shift';
                } else if (c.OwnerId == nightShiftQueue) {
                    // Reassign to morning shift
                    c.OwnerId = morningShiftQueue;
                    c.Initial_Shift_Name__c = 'Night Shift';
                }

                // Update the Assigned Shift Time to reflect the reassignment time
                c.Assigned_Shift_Time__c = System.now();
                casesToUpdate.add(c);
            }
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        } else {
            System.debug('No cases to update.');
        }
    }
}