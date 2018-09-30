@isTest
public class TestFactory {

    // List of Class Names stored in Metadata to enable Test Factory extentions be bundled and deployed with Packages
    private static final TestFactory__mdt[] TEST_FACTORIES = [SELECT ClassName__c FROM TestFactory__mdt];

    public static SObject createSObject(SObject sObj) {
        // Check what type of object we are creating and add any defaults that are needed.
		String objectName = String.valueOf(sObj.getSObjectType());
        // Construct the default values class. Salesforce doesn't allow '__' in class names
		String defaultClassName = objectName.replaceAll('__(c|C)$|__', '') + 'Defaults';
        // If there are any classes in TestFactory or an extention that exists for the default values, then use them
        String[] implementations = getImplementations(defaultClassName);
        if (implementations != null && !implementations.isEmpty()) {
            sObj = compileClasses(sObj, implementations);
        }
        return sObj;
    }

    public static SObject createSObject(SObject sObj, Boolean doInsert) {
        SObject retObject = createSObject(sObj);
        if (doInsert) {
            insert retObject;
        }
        return retObject;
    }

    public static SObject createSObject(SObject sObj, String defaultClassName) {
        // finds any implementations of field defaults with the defaultClassName
        String[] implementations = getImplementations(defaultClassName);
        if (implementations == null || implementations.isEmpty()) {
            throw new TestFactoryException('Invalid defaults class.');
        }
        return compileClasses(sObj, implementations);
    }

    public static SObject createSObject(SObject sObj, String defaultClassName, Boolean doInsert) {
        SObject retObject = createSObject(sObj, defaultClassName);
        if (doInsert) {
            insert retObject;
        }
        return retObject;
    }

    public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects) {
        return createSObjectList(sObj, numberOfObjects, (String)null);
    }

    public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, Boolean doInsert) {
        SObject[] retList = createSObjectList(sObj, numberOfObjects, (String)null);
        if (doInsert) {
            insert retList;
        }
        return retList;
    }

    public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, String defaultClassName, Boolean doInsert) {
        SObject[] retList = createSObjectList(sObj, numberOfObjects, defaultClassName);
        if (doInsert) {
            insert retList;
        }
        return retList;
    }

    public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects, String defaultClassName) {
        SObject[] sObjs = new SObject[] {};
        SObject newObj;

        // Get one copy of the object
        if (defaultClassName == null) {
            newObj = createSObject(sObj);
        } else {
            newObj = createSObject(sObj, defaultClassName);
        }

        // Get the name field for the object
        String nameField = nameFieldMap.get(String.valueOf(sObj.getSObjectType()));
        if (nameField == null) {
            nameField = 'Name';
        }

        // Clone the object the number of times requested. Increment the name field so each record is unique
        for (Integer i = 0; i < numberOfObjects; i++) {
            SObject clonedSObj = newObj.clone(false, true);
            clonedSObj.put(nameField, (String)clonedSObj.get(nameField) + ' ' + i);
            sObjs.add(clonedSObj);
        }
        return sObjs;
    }

    private static String[] getImplementations(String checkClassName) {
        String[] classNames = new String[]{};
        // checks for implimentation within TestFactory to ensure the TestFactory base is applied first for constistency
        String factoryClassName = 'TestFactory.' + checkClassName;
        if (Type.forName(factoryClassName) != null) {
            classNames.add(factoryClassName);
        }
        // checks for any extentions to test factory stored in metadata
        if (TEST_FACTORIES != null && !TEST_FACTORIES.isEmpty()) {
            for (TestFactory__mdt tf : TEST_FACTORIES) {
                factoryClassName = tf.ClassName__c + '.' + checkClassName;
                if (Type.forName(factoryClassName) != null) {
                    classNames.add(factoryClassName);
                }
            }
        }
        return classNames;
    }

    private static SObject compileClasses(SObject sObj, String[] classNames) {
        if (classNames != null && !classNames.isEmpty()) {
            for (String className : classNames) {
                Type t = Type.forName(className);
                FieldDefaults defaults = (FieldDefaults) t.newInstance();
                addFieldDefaults(sObj, defaults.getFieldDefaults());
            }
        }
        return sObj;
    }

    private static void addFieldDefaults(SObject sObj, Map<Schema.SObjectField, Object> defaults) {
        // Loop through the map of fields and if they weren't specifically assigned, fill them.
        Map<String, Object> populatedFields = sObj.getPopulatedFieldsAsMap();
        for (Schema.SObjectField field : defaults.keySet()) {
            if (!populatedFields.containsKey(String.valueOf(field))) {
                sObj.put(field, defaults.get(field));
            }
        }
    }

    // intended as a way for other classes to extend showing they are a plugin for TestFactory, mental mapping only
	public virtual class Plugin {}

    // When we create a list of SObjects, we need to
    private static Map<String, String> nameFieldMap = new Map<String, String> {
            'Contact' => 'LastName',
            'Case' => 'Subject'
    };

    public class TestFactoryException extends Exception {}

    // Use the FieldDefaults interface to set up values you want to default in for all objects.
    public interface FieldDefaults {
        Map<Schema.SObjectField, Object> getFieldDefaults();
    }

    // To specify defaults for objects, use the naming convention [ObjectName]Defaults.
    // For custom objects, omit the __c from the Object Name

	public class AccountDefaults implements FieldDefaults {
		public Map<Schema.SObjectField, Object> getFieldDefaults() {
			return new Map<Schema.SObjectField, Object> {
				Account.Name => 'Test Account'
			};
		}
	}

	public class ContactDefaults implements FieldDefaults {
		public Map<Schema.SObjectField, Object> getFieldDefaults() {
			return new Map<Schema.SObjectField, Object> {
				Contact.FirstName => 'First',
				Contact.LastName => 'Last'
			};
		}
	}

	public class OpportunityDefaults implements FieldDefaults {
		public Map<Schema.SObjectField, Object> getFieldDefaults() {
			return new Map<Schema.SObjectField, Object> {
				Opportunity.Name => 'Test Opportunity',
				Opportunity.StageName => 'Closed Won',
				Opportunity.CloseDate => System.today()
			};
		}
	}

	public class CaseDefaults implements FieldDefaults {
		public Map<Schema.SObjectField, Object> getFieldDefaults() {
			return new Map<Schema.SObjectField, Object> {
				Case.Subject => 'Test Case'
			};
		}
	}
}
