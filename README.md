Salesforce-Test-Factory
=======================

SObject factory that can be used in unit tests to create test data.
This is a fork of dhoechst repo: https://github.com/dhoechst/Salesforce-Test-Factory.
It keeps the same core functionality and exntends it.

Main features are:
- Auto-generatation of test data for required and unique fields. Required fields automatically get populated with random values if you set the param autoSetRequiredFields to true. You don't have to worry about unique fields either, they are incremented in bulk scenarios.
- RunAs(user) to test different scenarios for different users/profiles.
- Differentiate insertion and creation methods. If the method name start with "create", then it only creates the record without inserting it into the database. If the method starts with "insert", the record is created and inserted in the database.

Fields will get values following this order:
1- If you input values when calling the method, these values are prioritized and overrite everthing else.
2- If you don't input values, then the TestFactory will look for the defaults and use them (Default as per the original repo logic). 
3- If there is no default, then the TestFactory will automatically populates the fields.

In short, auto-population is used as last resort if the developer doesn't input data and there is no default.

All field types are supported by the auto-generation feature, except: Base64, EncryptedString, Time, Reference (lookup and master-detail).

Please keep in mind, that knowing the data and entering it manually is a better practice than generating it automatically. Auto-generation is made to save time on some specific scenarios. Don't rely 100% on auto-generation, as they can fail due to custom business validation rules and other customizations that might restrict input values.

You can extend this framework easily by creating other defaults or other methods for example, and this will allow you to support your custom business rules.

<a href="https://githubsfdeploy.herokuapp.com/?owner=dhoechst&repo=Salesforce-Test-Factory">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

Usage:

    // Single account creation, the TestFactory will use the defaults. Autopopulate is set to false here, so no auto test data generation is going to happen
    Account a = (Account)TestFactory.createSObject(new Account(), false);
    insert a;

    // Single account creation, the TestFactory will use the default and then generates data for all required fields if necessary
    Account a = (Account)TestFactory.createSObject(new Account(), true);
    insert a;
    
    // You can  set values to be used. Any values set in the constructor will override the defaults
    Opportunity o = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = a.Id), true);
    
    // You can also specify a specific set of overrides for different scenarios
    Account a = (Account)TestFactory.createSObject(new Account(), 'TestFactory.AccountDefaults', true);

    // You can insert directly into the DB using an insert method, and set the running user
    User myUser = [SELECT Id FROM User WHERE Name = 'Riadh' LIMIT 1];
    Account a = (Account)TestFactory.insertSObject(new Account(), true, myUser);
    
    // Get a bunch of records for testing bulk - autopopulation is set to true here, so unique and required fields are taking care of
    Account[] aList = (Account[])TestFactory.createSObjectList(new Account(), 200, true);
