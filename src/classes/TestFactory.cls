@isTest
global class TestFactory {
	// Get the fields for an object by object name as a string.
	public static Map<String, Schema.SObjectField> fieldMapForObject(string objectName) {
		return fieldMapForObject(Schema.getGlobalDescribe().get(objectName));
	}

	// get the fields for an object by Schema.SObjectType
	public static Map<String, Schema.SObjectField> fieldMapForObject(Schema.SObjectType objectType) {
		Schema.DescribeSObjectResult objectDescribeResult = objectType.getDescribe();
		Map<String, Schema.SObjectField> objectFieldMap = objectDescribeResult.fields.getMap();
		return objectFieldMap;
	}

	// generate a single record using the "default" defaults value map.
	public static SObject createSObject(SObject sObj) {
		String defaultClassName = 'TestFactory.' + String.valueOf(sObj.getSObjectType()).replace('__c', '') + 'Defaults';
		return createSObject(sObj, defaultClassName);
	}

	// generate a single record using a specific defaults class
	public static SObject createSObject(SObject sObj, String defaultClassName)
	{
		
		// Get the defaults map of values.
		Type t = Type.forName(defaultClassName);
		if (t == null) {
			throw new TestFactoryException('Invalid defaults class.');
		}
		FieldDefaults defaults = (FieldDefaults)t.newInstance();

		// Fill in the data for other requried fields.
		sObj = fillFields(sObj, defaults.getFieldDefaults());
		return sObj;
	}

	// Generate n sObjects based on an an input SObject and use the "default" defaults value map.
	public static SObject[] createNsObjects(Sobject sObj, Integer n)
	{
		String defaultClassName = 'TestFactory.' + String.valueOf(sObj.getSObjectType()).replace('__c', '') + 'Defaults';
		return createNsObjects(sObj, n, defaultClassName);
	}

	// Generate n sObjects based on an an input SObject and use the specified dfeaults value map: defaultClassName
	public static SObject[] createNsObjects(Sobject sObj, Integer n, String defaultClassName)
	{
		// Get the defaults map of values.
		Type t = Type.forName(defaultClassName);
		if (t == null) {
			throw new TestFactoryException('Invalid defaults class.');
		}
		FieldDefaults defaultClass = (FieldDefaults)t.newInstance();
		Map<String, Object> defaults = defaultClass.getFieldDefaults();

		// Clone n versions of the input sObject and then backfill required fields.
		sObject[] sObjects = new sObject[]{};
		for(Integer i=0; i<n; i++)
		{
			sObject obj = sObj.clone(false,false,false,false);
			obj = fillFields(obj, defaults);
			sObjects.add(obj);
		}
		return sObjects;
	}

	// Method takes an sobject and returns an sobject that's fill in with data for every required field or field that's in the defaults values map.
	public static sObject fillFields(sObject obj, Map<String, Object> defaults)
	{
		Map<String, Schema.SObjectField> fieldMap = fieldMapForObject(obj.getSObjectType());
		for(Schema.SObjectField f : fieldMap.values())
		{
			Schema.DescribeFieldResult fdesc = f.getDescribe();
			if(fieldIsRequired(fdesc,defaults))
			{
				obj.put(f,getFieldData(obj,fdesc,defaults));
			}
		}
		return obj;
	}

	// Method takes in the sObject, the field trying to be populated, and the defaults map.
	// Priority #1 is the sObjects current value (ie, it was specified in the sObject instance of the create methods.)
	// Priority #2 is the defaults class values.
	// Priority #3 is some randomized values based on field type. (sort of hacky)
	private static Object getFieldData(SObject obj, Schema.DescribeFieldResult dfr, Map<String,Object> defaults)
	{
		String fieldName = dfr.getName();
		Object retObject = obj.get(fieldName);
		Schema.DisplayType fieldType = dfr.getType();

		if(retObject == null)
		{
			if(defaults.containsKey(fieldName))
			{
				if(dfr.isUnique() || dfr.isNameField())
				{
					retObject = makeUnique((String)defaults.get(fieldName));
				}
				else
				{
					retObject = defaults.get(fieldName);
				}
			}
			else
			{
				if(STRINGY_TYPES.contains(fieldType))
				{
					retObject = makeRandom(dfr.getLength());
				}
				else if(DOUBLEY_TYPES.contains(fieldType)) 
				{
					retObject = 123.45 * Crypto.getRandomInteger();
				}
				else if(fieldtype == Schema.DisplayType.integer) 
				{
					retObject = Crypto.getRandomInteger();
				}
				else if (fieldtype == Schema.DisplayType.date) 
				{
					retObject = date.today().addDays(Integer.valueOf(Math.random()*123));
				}
				else if (fieldtype == Schema.DisplayType.datetime) 
				{
					retObject = datetime.now().addMinutes(Integer.valueOf(Math.random()*12345));
				}
				else if (fieldtype == Schema.DisplayType.email) 
				{
					retObject = 'test' + makeRandom(10) + '@example.com';
				}
				else if (fieldtype == Schema.DisplayType.phone) 
				{
					retObject = makePhone();
				}
				else 
				{
					throw new TestFactoryException('Invalid field. name is: ' + fieldName + ' type:' + fieldtype);
				}
			}
		}
		return retObject;
	}

	// Helper method to make an input string "more" unique.
	private static String makeUnique(String inputString)
	{
		return inputString + String.valueOf(makeRandom(3));
	}

	// helper method to create a string of the input length using some help from the crypto class.
	private static String makeRandom(Integer length)
	{
		// Create some random text.
		String randomText = EncodingUtil.convertToHex(crypto.generateAesKey(128));

		// If the text given to us by the crypto class doesn't meet our length requirement.
		//   we need to fill it some more "garbage" text to make it unique and the length we want.
		//   This is hacky but should work.
		if(randomText.length() < length) {
			double numreps = System.math.ceil(length - randomText.length());
			String extraText = '';
			for(integer i =0; i < numreps; i++) {
				extraText += randomText.reverse().leftPad(i).left(1);
			}
			randomText += extraText;
		}
		return randomText.substring(0,length);
	}

	// Make a unique phone number that arbitrarily starts with the number 5.
	private static String makePhone()
	{
		String retString = '5';
		for(Integer i=1; i<9; i++)
		{
			retString += String.valueOf(Math.floor(Math.random()*10));
		}
		return retString;
	}

	private static Set<Schema.DisplayType> STRINGY_TYPES = new Set<Schema.DisplayType>{
		Schema.DisplayType.combobox,
		Schema.DisplayType.ID,
		Schema.DisplayType.multipicklist,
		Schema.DisplayType.picklist,
		Schema.DisplayType.string
	};

	private static Set<Schema.DisplayType> DOUBLEY_TYPES = new Set<Schema.DisplayType>{
		Schema.DisplayType.currency,
		Schema.DisplayType.percent,
		Schema.DisplayType.double
	};

	// determine if the field is required or if it should be filled in based on the defaults class.
	// This method doesn't exactly fit its name but it gets the job done.
	private static Boolean fieldIsRequired (Schema.DescribeFieldResult dfr, Map<String, Object> defaults)
	{
		// the combination of createable, not nillable, not defaultedonCreate,not Autonumber, and Not calculated means the field is "required"
		// Hopefully we get a better way to do this in the future? Maybe someone knows a better way now?
		// This if also allows fields that are in the defaults class to be filled in.
		Boolean isRequired = false;
		if((dfr.isCreateable() && 
			!dfr.isNillable() && 
			!dfr.isDefaultedOnCreate() && 
			!dfr.isAutoNumber() && 
			!dfr.isCalculated()) ||
			(defaults.containsKey(dfr.getName()) && dfr.isUpdateable()))
		{
			isRequired = true;
		}
		return isRequired;
	}

	public class TestFactoryException extends Exception {}

	// Use the FieldDefaults interface to set up values you want to default in for all objects.
	public interface FieldDefaults {
		Map<String, Object> getFieldDefaults();
	}

	// To specify defaults for objects, use the naming convention [ObjectName]Defaults.
	// For custom objects, omit the __c from the Object Name
	public class AccountDefaults implements FieldDefaults{
		public Map<String, Object> getFieldDefaults() {
			return new Map<String, Object> {
				'Name' => 'Test Account'
			};
		}
	}

	public class ContactDefaults implements FieldDefaults{
		public Map<String, Object> getFieldDefaults() {
			return new Map<String, Object> {
				'FirstName' => 'First',
				'LastName' => 'Last'
			};
		}
	}

	public class OpportunityDefaults implements FieldDefaults{
		public Map<String, Object> getFieldDefaults() {
			return new Map<String, Object> {
				'Name' => 'Test Opportunity',
				'StageName' => 'Closed Won',
				'CloseDate' => System.today()
			};
		}
	}

	public class CaseDefaults implements FieldDefaults{
		public Map<String, Object> getFieldDefaults() {
			return new Map<String, Object> {
				'Subject' => 'Test Case'
			};
		}
	}
}