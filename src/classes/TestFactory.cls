@isTest
public class TestFactory {

	public static List<Schema.DescribeFieldResult> requiredFields;

	public static SObject createSObject(SObject sObj) {
		// Check what type of object we are creating and add any defaults that are needed.
		String objectName = String.valueOf(sObj.getSObjectType());
		// Construct the default values class. Salesforce doesn't allow '__' in class names
		String defaultClassName = 'TestFactory.' + objectName.replaceAll('__(c|C)$|__', '') + 'Defaults';
		// If there is a class that exists for the default values, then use them
		if (Type.forName(defaultClassName) != null) {
			sObj = createSObject(sObj, defaultClassName);
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
		// Create an instance of the defaults class so we can get the Map of field defaults
		Type t = Type.forName(defaultClassName);
		if (t == null) {
			Throw new TestFactoryException('Invalid defaults class.');
		}
		FieldDefaults defaults = (FieldDefaults)t.newInstance();
		addFieldDefaults(sObj, defaults.getFieldDefaults());
		return sObj;
	}

	public static SObject createSObject(SObject sObj, String defaultClassName, Boolean doInsert) {
		SObject retObject = createSObject(sObj, defaultClassName);
		if (doInsert) {
			insert retObject;
		}
		return retObject;
	}

	 /**
	 * The method automatically setups random values for required custom fields for the given object
	 * But only if the user didn't input values or default value doesn't exist.
	 * As a first step, only these types are supported: 'STRING', 'TEXTAREA', 'EMAIL', 'URL'
	 * More to be supported in the future: base64, currency, Date, Datetime, Double, Integer, Multipicklist, Picklist, percent
	 * @param  sObj                    sobject token
	 * @return                         generic sobject for testing purposes, with custom required fields randomly populated
	 */
	public static SObject createSObjectRequired(SObject sObj) {
		SObject retObject = createSObject(sObj);

		Map<String, Object> map_populatedFields = retObject.getPopulatedFieldsAsMap();
		if (requiredFields == null) {
			requiredFields = getRequiredCustomFields(retObject);
		}

		for (Schema.DescribeFieldResult fieldDesc : requiredFields) {
			Schema.SObjectField fieldToken = fieldDesc.getSObjectField();
			String currentType = fieldDesc.getType().name().toUpperCase();

			// If the required custom field is already populated, continue
			if (!map_populatedFields.containsKey(String.valueOf(fieldToken))) {
				Object randomFieldVal;
				// If current type is String
				if (currentType == 'STRING' || currentType == 'TEXTAREA') {
					Integer fieldLength = fieldDesc.getLength() > 20 ? 20 : fieldDesc.getLength();
					randomFieldVal = getRandomStr(fieldLength);
				}
				// If current type is email
				else if (currentType == 'EMAIL') {
					randomFieldVal = getRandomStr(10) + '@' + getRandomStr(7) + '.com';
				}
				else if (currentType == 'URL') {
					randomFieldVal = 'http://' + getRandomStr(10) + '.com';
				}
				// Finally, populate the record with the required fields
				retObject.put(fieldToken, randomFieldVal);
			}	
		}

		return retObject;
	}

	public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects) {
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

	public static SObject[] createSObjectRequiredList(Sobject sObj, Integer numberOfObjects) {
		SObject[] sObjs = new SObject[] {};

		// Get the name field for the object
		String nameField = nameFieldMap.get(String.valueOf(sObj.getSObjectType()));
		if (nameField == null) {
			nameField = 'Name';
		}

		for (Integer i = 0; i < numberOfObjects; i++) {
			SObject clonedSObj = sObj.clone(false, true);
			clonedSObj = createSObjectRequired(clonedSObj);
			clonedSObj.put(nameField, (String)clonedSObj.get(nameField) + '' + i);
			sObjs.add(clonedSObj);
		}
		return sObjs;
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

	/**
	 * Generate a random String given its size
	 * @param  size: length of the String
	 * @return     Random String
	 */
    public static String getRandomStr(Integer size) {
        final String lst_range = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randomStr = '';
        for(Integer i = 0; i < size; i++) {
           Integer randomIndex = Math.mod(Math.abs(Crypto.getRandomInteger()), lst_range.length());
           randomStr += lst_range.substring(randomIndex, randomIndex + 1);
        }
        return randomStr; 
    }

    /**
     * Given a sobject, the method provides the list of required custom fields except formulas, auto-number
     * and field with already a default value defined
     * @param  sObj sobject token
     * @return      List<Schema.DescribeFieldResult> of required custom fields
     */
    public static List<Schema.DescribeFieldResult> getRequiredCustomFields(SObject sObj) {
    	String objectName = String.valueOf(sObj.getSObjectType());
		List<Schema.DescribeFieldResult> lst_requiredFields = new List<Schema.DescribeFieldResult>();
		List<Schema.SObjectField> lst_fields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values();
		
		for(Schema.SObjectField field : lst_fields) { 
			Schema.DescribeFieldResult fieldDesc = field.getDescribe();
			if (!fieldDesc.isNillable() && !fieldDesc.isAutoNumber() && !fieldDesc.isCalculated() 
				&& !fieldDesc.isDefaultedOnCreate() && fieldDesc.isCustom()) 
			{
				lst_requiredFields.add(fieldDesc);
			}
		}
		return lst_requiredFields;	
    }

}