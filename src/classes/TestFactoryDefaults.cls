@isTest
public class TestFactoryDefaults{

  // To specify defaults for objects, use the naming convention [ObjectName]Defaults.
  // For custom objects, omit the __c from the Object Name

	public class UserDefaults implements TestFactory.FieldDefaults {
		public Map<Schema.SObjectField, Object> getFieldDefaults() {
			String lastName = 'Tester';
      Integer uniqueInteger = System.now().millisecond();
      return new Map<Schema.SObjectField, Object> {
        User.FirstName         => 'Inigo Montoya',
        User.LastName          => lastName,
        User.Alias             => EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(lastName + uniqueInteger))).substring(0,8),
        User.Email             => lastName + '.' + uniqueInteger + '.' + UserInfo.getOrganizationId() + '@example.com',
        User.Username          => lastName + '.' + uniqueInteger + '@example.com.' + UserInfo.getOrganizationId(),
        User.ProfileId         => [SELECT Id FROM Profile WHERE Name  = 'System Administrator' LIMIT 1].Id,
        // User.UserRoleId     => [SELECT Id FROM UserRole WHERE Name = 'CEO' LIMIT 1].Id,
        User.TimeZoneSidKey    => 'America/Chicago',
        User.LanguageLocaleKey => 'en_US',
        User.EmailEncodingKey  => 'UTF-8',
        User.LocaleSidKey      => 'en_US'
			};
		}
	}

  public class AccountDefaults implements TestFactory.FieldDefaults {
    public Map<Schema.SObjectField, Object> getFieldDefaults() {
      return new Map<Schema.SObjectField, Object> {
        Account.Name => 'Test Account'
      };
    }
  }

  public class MyAccountDefaults implements TestFactory.FieldDefaults {
    public Map<Schema.SObjectField, Object> getFieldDefaults() {
      return new Map<Schema.SObjectField, Object> {
        Account.Name => 'My Test Account'
      };
    }
  }

  public class ContactDefaults implements TestFactory.FieldDefaults {
    public Map<Schema.SObjectField, Object> getFieldDefaults() {
      return new Map<Schema.SObjectField, Object> {
        Contact.FirstName => 'First',
        Contact.LastName  => 'Last'
      };
    }
  }

  public class OpportunityDefaults implements TestFactory.FieldDefaults {
    public Map<Schema.SObjectField, Object> getFieldDefaults() {
      return new Map<Schema.SObjectField, Object> {
        Opportunity.Name      => 'Test Opportunity',
        Opportunity.StageName => 'Closed Won',
        Opportunity.CloseDate => System.today()
      };
    }
  }

  public class CaseDefaults implements TestFactory.FieldDefaults {
    public Map<Schema.SObjectField, Object> getFieldDefaults() {
      return new Map<Schema.SObjectField, Object> {
        Case.Subject => 'Test Case'
      };
    }
  }
}