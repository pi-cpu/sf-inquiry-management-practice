trigger CaseTrigger on Case (before insert, before update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        CaseTriggerHandler.handleBeforeInsert(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        CaseTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
}
