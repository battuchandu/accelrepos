global class scheduleClass  implements Schedulable {
  global void execute(SchedulableContext sc) {
   CaseShiftReassignmentHelper.reassignCases();
  }
    
}