/**
 * TriggerX by Sebastian Wagner 2013
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted.
 *
 * Sample Implementation of a TriggerHandler for TriggerX
 * http://github.com/sebwagner/TriggerX
 */
public class AccountSampleHandler extends TriggerX {


    public override void onBeforeUpdate(Map<Id,sObject> triggerOldMap){

        Set<Id> updatedIds = TriggerX.getUpdatedIds();

        for (Account record:(Account[])records)
        {
            // skip records which have been updated within the current context
            if (updatedIds.contains(record.Id)) continue;

        }
        // more logic goes here
    }


    // Method executed to perform AFTER_UPDATE operations, overwrite if applicable
    public override void onAfterUpdate(Map<Id,sObject> triggerOldMap){

        Map<Id,Account> withAddressUpdate = new Map<Id,Account>();

        sObjectField[] addressFields = new sObjectField[]{
              Account.BillingStreet
            , Account.BillingPostalCode
            , Account.BillingCity
            , Account.BillingCountry};

        // use prefiltered list
        for (Account record:(Account[])getNonRecursiveUpdates())
        {
            // check if the address has change and keep record for further processing if so
            if (TriggerX.hasChangedFields(addressFields, record, triggerOldMap.get(record.Id)))
            {
                withAddressUpdate.put(record.Id,record);
            }
        }

        // track updated ids to prevent recursive updates
        TriggerX.addUpdatedIds(triggerOldMap.keySet()); 

        if (withAddressUpdate.size() > 0)
        {
            updateContactAddressFromAccount(withAddressUpdate);
        }

        // more logic goes here
    }
    

    private void updateContactAddressFromAccount(Map<Id,Account> accountMap){

        Contact[] contacts = [
            select Id
                 , AccountId
              from Contact
             where AccountId IN: accountMap.keySet()];

        for (Contact record:contacts)
        {

        	Account acc = accountMap.get(record.AccountId);

            record.MailingCity = acc.BillingCity;            
            record.MailingCountry = acc.BillingCountry;
            record.MailingPostalCode = acc.BillingPostalCode;
            record.MailingStreet = acc.BillingStreet;
        }

        // disable Account updates before saving the contacts, so we dont have to run it twice 
        TriggerX.disable(AccountSampleHandler.class, TriggerX.getUpdateEvents());

        update contacts;

        // reenable updates for futher processing
        TriggerX.enable(AccountSampleHandler.class, TriggerX.getUpdateEvents());
    }
    

    @isTest
    private static void stupidTest(){

        // just cover the trigger
        Account record = new Account(Name = 'TEST_ACCOUNT');
        try
        {
            insert record;
            
            // create contact
            Contact contact = new Contact(
                AccountId = record.Id
                , LastName = 'LAST_NAME');
            insert contact;

            record.BillingStreet = 'Street';
            update record;

            Map<Id,Account> accMap = new Map<Id,Account>();

            TriggerX handler = new AccountSampleHandler().doConstruct(new sObject[]{record});
            handler.onBeforeUpdate(accMap);
            handler.onAfterUpdate(accMap);
        }
        catch(Exception ex)
        {

        }
    }
    
}