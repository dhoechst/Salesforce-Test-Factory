@isTest
public class TestFactory {

	// Cached metadata structure
	public static Map<String, List<Schema.DescribeFieldResult>> requiredFieldsMap = new Map<String, List<Schema.DescribeFieldResult>>();
	public static Map<String, Map<String, Schema.SObjectField>> sobjectToFieldsMap = new Map<String, Map<String, Schema.SObjectField>>();
	public static Map<String, List<String>> uniqueFieldsMap = new Map<String, List<String>>();

	public static SObject createSObject(SObject sObj, Boolean autoSetRequiredFields) {
		// Check what type of object we are creating and add any defaults that are needed.
		String objectName = String.valueOf(sObj.getSObjectType());
		// Construct the default values class. Salesforce doesn't allow '__' in class names
		String defaultClassName = 'TestFactory.' + objectName.replaceAll('__(c|C)$|__', '') + 'Defaults';
		// If there is a class that exists for the default values, then use them
		if (Type.forName(defaultClassName) != null) {
			sObj = createSObject(sObj, defaultClassName, autoSetRequiredFields);
		}
		return sObj;
	}

	public static SObject insertSObject(SObject sObj, Boolean autoSetRequiredFields) {
		SObject retObject = createSObject(sObj, autoSetRequiredFields);
		if (autoSetRequiredFields) {
			addRequiredFields(retObject);
		}
		insert retObject;
		return retObject;
	}

	public static SObject insertSObject(SObject sObj, Boolean autoSetRequiredFields, User usr) {
		if (usr != null) {
			System.runAs(usr) {
				return insertSObject(sObj, autoSetRequiredFields);
			}
		}
		return insertSObject(sObj, autoSetRequiredFields);
	}

	public static SObject createSObject(SObject sObj, String defaultClassName, Boolean autoSetRequiredFields) {
		// Create an instance of the defaults class so we can get the Map of field defaults
		Type t = Type.forName(defaultClassName);
		if (t == null) {
			Throw new TestFactoryException('Invalid defaults class.');
		}
		FieldDefaults defaults = (FieldDefaults)t.newInstance();
		addFieldDefaults(sObj, defaults.getFieldDefaults());

		if (autoSetRequiredFields) {
			addRequiredFields(sObj);
		}
		return sObj;
	}

	public static SObject insertSObject(SObject sObj, String defaultClassName, Boolean autoSetRequiredFields) {
		SObject retObject = createSObject(sObj, defaultClassName, autoSetRequiredFields);
		if (autoSetRequiredFields) {
			addRequiredFields(retObject);
		}
		insert retObject;
		return retObject;
	}

	public static SObject insertSObject(SObject sObj, String defaultClassName, Boolean autoSetRequiredFields, User usr) {
		if (usr != null) {
			System.runAs(usr) {
				return insertSObject(sObj, defaultClassName, autoSetRequiredFields);
			}
		}
		return insertSObject(sObj, defaultClassName, autoSetRequiredFields);
	}

	public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects, Boolean autoSetRequiredFields) {
		return createSObjectList(sObj, numberOfObjects, (String)null, autoSetRequiredFields);
	}

	public static SObject[] insertSObjectList(SObject sObj, Integer numberOfObjects, Boolean autoSetRequiredFields) {
		SObject[] retList = createSObjectList(sObj, numberOfObjects, (String)null, autoSetRequiredFields);
		insert retList;
		return retList;
	}

	public static SObject[] insertSObjectList(SObject sObj, Integer numberOfObjects, Boolean autoSetRequiredFields, User usr) {
		if (usr != null) {
			System.runAs(usr) {
				return insertSObjectList(sObj, numberOfObjects, autoSetRequiredFields);
			}
		}
		return insertSObjectList(sObj, numberOfObjects, autoSetRequiredFields);
	}

	public static SObject[] insertSObjectList(SObject sObj, Integer numberOfObjects, String defaultClassName, Boolean autoSetRequiredFields) {
		SObject[] retList = createSObjectList(sObj, numberOfObjects, defaultClassName, autoSetRequiredFields);
		insert retList;
		return retList;
	}

	public static SObject[] insertSObjectList(SObject sObj, Integer numberOfObjects, String defaultClassName, Boolean autoSetRequiredFields, User usr) {
		if (usr != null) {
			System.runAs(usr) {
				return insertSObjectList(sObj, numberOfObjects, defaultClassName, autoSetRequiredFields);
			}
		}
		return insertSObjectList(sObj, numberOfObjects, defaultClassName, autoSetRequiredFields);
	}

	public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects, String defaultClassName, Boolean autoSetRequiredFields) {
		String objectName = String.valueOf(sObj.getSObjectType());
		SObject[] sObjs = new SObject[] {};
		SObject newObj;

		// Get one single copy of the object
		if (defaultClassName != null) {
			newObj = createSObject(sObj, defaultClassName, autoSetRequiredFields);
		} 
		else {
			newObj = createSObject(sObj, autoSetRequiredFields);
		}

		if (!uniqueFieldsMap.containsKey(objectName)) {
			uniqueFieldsMap.put(objectName, getUniqueCustomFields(objectName));
		}

		List<String> lst_uniqueFields = new List<String>();
		// Get the name field for the object
		String nameField = nameFieldMap.get(String.valueOf(sObj.getSObjectType()));
		if (nameField == null) {
			nameField = 'Name';
		}
		lst_uniqueFields.add(nameField);

		// Get other unique custom fields for the object
		lst_uniqueFields.addAll(uniqueFieldsMap.get(objectName));

		// Clone the object the number of times requested. Increment the name field + unique fields so each record is unique
		for (Integer i = 0; i < numberOfObjects; i++) {
			SObject clonedSObj = newObj.clone(false, true);
			for (String uniqueField : lst_uniqueFields) {
				clonedSObj.put(uniqueField, (String)clonedSObj.get(uniqueField) + '' + i);
			}
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
	 * The method automatically setups random values for required custom fields for the given sobject.
	 * But only the fields that were not already populated get a random value.
	 * For now, only the following types are supported: 'STRING', 'TEXTAREA', 'EMAIL', 'URL'
	 * More to be supported in the future: base64, currency, Date, Datetime, Double, Integer, Multipicklist, Picklist, percent
	 * @param  sObj                    sobject token
	 * @return                         generic sobject for testing purposes, with custom required fields randomly populated
	 */
	public static void addRequiredFields(SObject sObj) {
		String objectName = String.valueOf(sObj.getSObjectType());
		Map<String, Object> map_populatedFields = sObj.getPopulatedFieldsAsMap();

		if (!requiredFieldsMap.containsKey(objectName)) {
			requiredFieldsMap.put(objectName, getRequiredCustomFields(objectName));
		}

		List<Schema.DescribeFieldResult> lst_requiredFields = requiredFieldsMap.get(objectName);
		for (Schema.DescribeFieldResult fieldDesc : lst_requiredFields) {
			Schema.SObjectField fieldToken = fieldDesc.getSObjectField();
			String currentType = fieldDesc.getType().name().toUpperCase();

			// Only generate a random valu when the field is not already populated
			if (!map_populatedFields.containsKey(String.valueOf(fieldToken))) {
				Object randomFieldVal;
				// If current type is String
				if (currentType == 'STRING' || currentType == 'TEXTAREA') {
					Integer fieldLength = fieldDesc.getLength() > 4 ? 4 : fieldDesc.getLength();
					randomFieldVal = getRandomStr(fieldLength);
				}
				// If current field type is email
				else if (currentType == 'EMAIL') {
					randomFieldVal = getRandomStr(4) + '@' + getRandomStr(4) + '.com';
				}
				// If current field type is URL
				else if (currentType == 'URL') {
					randomFieldVal = 'http://' + getRandomStr(4) + '.com';
				}
				// Finally, populate the record with the required fields
				sObj.put(fieldToken, randomFieldVal);
			}	
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

    public static List<Schema.DescribeFieldResult> getRequiredCustomFields(String objectName) {
		List<Schema.DescribeFieldResult> lst_requiredFields = new List<Schema.DescribeFieldResult>();
		
		if (!sobjectToFieldsMap.containsKey(objectName)) {
			sobjectToFieldsMap.put(objectName, Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap());
		}

		List<Schema.SObjectField> lst_fields = sobjectToFieldsMap.get(objectName).values();
		for(Schema.SObjectField field : lst_fields) { 
			Schema.DescribeFieldResult fieldDesc = field.getDescribe();
			if ( (!fieldDesc.isAutoNumber() && !fieldDesc.isCalculated() && fieldDesc.isCustom()) && 
				 (!fieldDesc.isNillable() || fieldDesc.isUnique()) 
			)
			{
				lst_requiredFields.add(fieldDesc);
			}
		}
		return lst_requiredFields;	
    }

    public static List<String> getUniqueCustomFields(String objectName) {
		List<String> lst_uniqueFields = new List<String>();

		if (!sobjectToFieldsMap.containsKey(objectName)) {
			sobjectToFieldsMap.put(objectName, Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap());
		}
		
		Map<String, Schema.SObjectField> map_fields = sobjectToFieldsMap.get(objectName);
		Set<String> set_fieldNames = map_fields.keySet();
		for(String fieldName : set_fieldNames) { 
			Schema.DescribeFieldResult fieldDesc = map_fields.get(fieldName).getDescribe();
			if (fieldDesc.isUnique() && !fieldDesc.isAutoNumber() && fieldDesc.isCustom()) {
				lst_uniqueFields.add(fieldName);
			}
		}
		return lst_uniqueFields;	
    }

}