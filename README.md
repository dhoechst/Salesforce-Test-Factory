Salesforce-Test-Factory
=======================

SObject factory that can be used in unit tests to create test data.

Usage:

    Account a = (Account)TestFactory.createSObject(new Account());
    insert a;
    Opportunity o = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = a.Id));
    insert o;
