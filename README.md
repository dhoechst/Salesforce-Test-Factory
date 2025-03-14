Salesforce-Test-Factory
=======================

SObject factory that can be used in unit tests to create test data.

Install as an unlocked package: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t2G000000Y19lQAC

Usage:

```java

    // The TestFactory will pre-fill all the fields we typically need, based on the TestFactoryDefaults class
    Account a = (Account)TestFactory.createSObject(new Account());
    insert a;

    // You can also set values to be used. Any values set in the constructor will override the defaults
    Opportunity o = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = a.Id));

    // You can also specify a specific set of overrides for different scenarios
    Account a = (Account)TestFactory.createSObject(new Account(), 'MyAccountDefaults');

    // Finally, get a bunch of records for testing bulk
    Account[] aList = (Account[])TestFactory.createSObjectList(new Account(), 200);

    // You can optionally insert records as created like this:
    // Note the final parameter of true.
    Account a = (Account) TestFactory.createSObject(new Account(), true);
    Contact c = (Contact) TestFactory.createSObject(new Contact(AccountID = a.Id), true);

```
