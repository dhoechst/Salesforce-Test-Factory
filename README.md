Salesforce-Test-Factory
=======================

SObject factory that can be used in unit tests to create test data.

<a href="https://githubsfdeploy.herokuapp.com/?owner=dhoechst&repo=Salesforce-Test-Factory">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

Usage:

    // The TestFactory will pre-fill all the fields we typically need
    Account a = (Account)TestFactory.createSObject(new Account());
    insert a;
    
    // You can also set values to be used. Any values set in the constructor will override the defaults
    Opportunity o = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = a.Id));
    
    // You can also specify a specific set of overrides for different scenarios
    Account a = (Account)TestFactory.createSObject(new Account(), 'TestFactory.AccountDefaults');
    
    // Finally, get a bunch of records for testing bulk
    Account acc = new Account(Name = 'Names rock',BillingStreet = 'street',BillingState='state',BillingCity='city',BillingPostalCode='12345');
    Account[] accounts = (Account[])TestFactory.createNsObjects(acc,15);
    insert accounts;