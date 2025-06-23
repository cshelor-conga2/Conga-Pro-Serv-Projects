/**
* @author Conga Services
* @date 20181002
* @version 1.00
* @description AssetHelper - Custom functionality for the Asset object
*/
public with sharing class AssetHelper {
	public static Set<Id> CXGProductIds = new Set<Id>{ '01t50000005BAf7AAG','01t50000005BAfCAAW','01t50000005BAfHAAW','01t50000005BAf2AAG','01t50000005At7RAAS' };


    /**
    * @description updateLeapYearFlag - Updates the Has_Feb_Leap_Year_Day__c field using the UtilityClass.checkRangeForLeapYear method
    */
    public static void updateLeapYearFlag(List<Asset> newOrUpdatedAssets, Map<Id, Asset> outdatedAssets){
        try{
            if(TriggerHelper.DoExecute('AssetHelper','updateLeapYearFlag') && newOrUpdatedAssets != null){
                // CHECK EACH SUBSCRIPTION TO SEE IF IT QUALIFIES
                List<Asset> qualifiedAssets = new List<Asset>();
                for(Asset newOrUpdatedAsset : newOrUpdatedAssets){
                    Asset outdatedAsset = outdatedAssets != null ? outdatedAssets.get(newOrUpdatedAsset.Id) : null;
                    if(outdatedAsset == null || (outdatedAsset != null && (newOrUpdatedAsset.Start_Date__c != outdatedAsset.Start_Date__c ||
                                                                           newOrUpdatedAsset.End_Date__c != outdatedAsset.End_Date__c))){
                        // NEW ASSET OR UPDATED ASSET WITH CHANGED START DAT OR END DATE, ASSET QUALIFIES
                        qualifiedAssets.add(newOrUpdatedAsset);
                    }
                }

                if(!qualifiedAssets.isEmpty()){
                    // UPDATE ASSET LEAP YEAR FLAGS
                    for(Asset asset : qualifiedAssets){
                        asset.Has_Leap_Year_Day__c = UtilityClass.checkRangeForLeapYear(asset.Start_Date__c, asset.End_Date__c);
                    }
                }

                // END AUDIT IF ONE IS STARTED
	            TriggerHelper.EndExecute('AssetHelper', 'updateLeapYearFlag');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('AssetHelper', 'updateLeapYearFlag', newOrUpdatedAssets, ex, true);
        }
    }

	/**
	* @description updateAccountIsPreferred - Sets the IsPreferred__c checkbox on parent accounts to true if the new Assets have qualifying names.
	* @param List<Account> newAssets - New or Updated Asset records
	* @return void
	*/
     public static void updateAccountIsPreferred(List<Asset> newAssets){
     	try{
	        if(TriggerHelper.DoExecute('AssetHelper','updateAccountIsPreferred') && newAssets != null){
	        	// GET ACCOUNT IDS FROM QUALIFYING ASSETS
	            Set<Id> accountIds = new Set<Id>();
	            for(Asset asset : newAssets){
	                if(asset.Name == 'Preferred Support' || asset.Name == 'Preferred Support For Conga Invoicing for Salesforce Billing'){
	                    accountIds.add(asset.AccountId);
	                }
	            }

	            // GET ACCOUNTS THAT NEED TO HAVE IS PREFERRED CHECKED AND UPDATE THEM
	            if(!accountIds.isEmpty()){
	                List<Account> accountsToUpdate = new List<Account>();
	                for(Account acct : [SELECT Id, IsPreferred__c FROM Account WHERE Id IN :accountIds AND IsPreferred__c = false]){
	                    acct.IsPreferred__c = true;
	                    accountsToUpdate.add(acct);
	                }

	                // COMMIT ACCOUNT CHANGES
	                if(!accountsToUpdate.isEmpty()){
                        Database.saveResult[] accountResults = Database.update(accountsToUpdate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(accountResults, 'AssetHelper', 'updateAccountIsPreferred', true);
	                }
	            }

	            // END AUDIT IF ONE IS STARTED
	            TriggerHelper.EndExecute('AssetHelper', 'updateAccountIsPreferred');
	        }
	    }
	    catch(Exception ex){
            SystemIssueLogHelper.LogException('AssetHelper', 'updateAccountIsPreferred', newAssets, ex, true); 	
	    }
    }

	/**
	* @description updateOppLineItem - Populates the Asset__c field of opp line items with the assets that were derived from them.
	* @param List<Asset> newAssets - New or Updated Asset records
	* @return void
	*/
	public static void updateOppLineItem(List<Asset> newAssets){
		try{
			if(TriggerHelper.DoExecute('AssetHelper','updateOppLineItem') && newAssets != null){
				// UPDATE OPP ITEMS FROM WHICH THE ASSETS CAME FROM 
				List<OpportunityLineItem> oppItemsToUpdate = new List<OpportunityLineItem>();
				for(Asset asset : newAssets){
					if(String.isNotBlank(asset.OLI_Id__c) && UtilityClass.validateId(asset.OLI_Id__c)){
						oppItemsToUpdate.add(new OpportunityLineItem(Id = (Id)asset.OLI_Id__c, Asset__c = asset.Id));
					}
				}

				// COMMIT OPP ITEM UPDATES
				if(!oppItemsToUpdate.isEmpty()){
					Database.saveResult[] oppItemResults = Database.update(oppItemsToUpdate, false);
                    SystemIssueLogHelper.CheckForDatabaseErrors(oppItemResults, 'AssetHelper', 'updateOppLineItem', true);
				}

				// END AUDIT IF ONE IS STARTED
				TriggerHelper.EndExecute('AssetHelper', 'updateOppLineItem');
			}
		}
		catch(Exception ex){
            SystemIssueLogHelper.LogException('AssetHelper', 'updateOppLineItem', newAssets, ex, true);
		}
	}

	/**
	* @description calculateAccountType - Executes the BatchableSch_AccountTypeCalculator batch class that calculates an Account's Type based on its Assets
	* @param List<Asset> newOrUpdatedAssets - New or updated Asset records
	* @param List<Asset> outdatedOrDeletedAssets - Outdated or deleted Asset records
	* @return void
	*/
	public static void calculateAccountType(List<Asset> newOrUpdatedAssets, Map<Id, Asset> outdatedOrDeletedAssets){
		try{
			if(TriggerHelper.DoExecute('AssetHelper','calculateAccountType')){
				
				// GET PARENT ACCOUNT IDS FROM QUALIFIED ASSETS
				Set<Id> parentAccountIds = new Set<Id>();
				if(newOrUpdatedAssets != null){
	                for(Asset newOrUpdatedAsset : newOrUpdatedAssets){
	                    Asset outdatedAsset = outdatedOrDeletedAssets != null ? outdatedOrDeletedAssets.get(newOrUpdatedAsset.Id) : null;
	                    if(outdatedAsset == null || newOrUpdatedAsset.Entitlement_Status__c != outdatedAsset.Entitlement_Status__c){
	                        // NEW OR HAS A QUALIFYING CHANGE
	                        parentAccountIds.add(newOrUpdatedAsset.AccountId);
	                    }
	                }
				}
				else if(newOrUpdatedAssets == null && outdatedOrDeletedAssets != null){
					// ASSET DELETED, ALL QUALIFY
					for(Asset deletedAsset : outdatedOrDeletedAssets.values()){
						parentAccountIds.add(deletedAsset.AccountId);
					}
				}

				// EXECUTE BATCH CLASS WITH ACCOUNT IDS
				if(!parentAccountIds.isEmpty()){
					Database.executeBatch(new BatchableSch_AccountTypeCalculator(parentAccountIds));
				}

				// END AUDIT IF ONE IS STARTED
				TriggerHelper.EndExecute('AssetHelper', 'calculateAccountType');
			}
		}
		catch(Exception ex){
            SystemIssueLogHelper.LogException('AssetHelper', 'calculateAccountType', (newOrUpdatedAssets != null ? newOrUpdatedAssets : outdatedOrDeletedAssets.values()), ex, true);
		}
	}

    /**
    * @author Conga Services, ERedding
    * @date 20200413
    * @description updateCxQDateOnParentAcct - Updates the "Has CxQ Asset Start Date" on Parent Accounts
    *                                           --- EXECUTED FROM ASSET AFTER INSERT, AFTER UPDATE, AND AFTER DELETE TRIGGERS ---
    * @param List<Asset> newOrUpdatedAssets - New or updated Asset records
    * @param List<Asset> outdatedOrDeletedAssets - Outdated or deleted Asset records
    * @return void
    */
    public static void updateCxQDateOnParentAcct(List<Asset> newOrUpdatedAssets, Map<Id, Asset> outdatedOrDeletedAssets){
        try{
            if(TriggerHelper.DoExecute('AssetHelper','updateCxQDateOnParentAcct')){

				// GET PARENT ACCOUNT IDS FROM QUALIFIED ASSETS
				Set<Id> parentAccountIds = new Set<Id>();
				if(newOrUpdatedAssets != null){
	                for(Asset newOrUpdatedAsset : newOrUpdatedAssets){
	                    Asset outdatedAsset = outdatedOrDeletedAssets != null ? outdatedOrDeletedAssets.get(newOrUpdatedAsset.Id) : null;
	                    if((CXGProductIds.contains(newOrUpdatedAsset.Product2Id) && (outdatedAsset == null || newOrUpdatedAsset.Start_Date__c != outdatedAsset.Start_Date__c)) ||
	                       (outdatedAsset != null && !CXGProductIds.contains(newOrUpdatedAsset.Product2Id) && CXGProductIds.contains(outdatedAsset.Product2Id))){
	                        // NEW OR HAS A QUALIFYING CHANGE
	                        parentAccountIds.add(newOrUpdatedAsset.AccountId);
	                    }
	                }
				}
				else if(newOrUpdatedAssets == null && outdatedOrDeletedAssets != null){
					// ASSET DELETED
					for(Asset deletedAsset : outdatedOrDeletedAssets.values()){
						if(CXGProductIds.contains(deletedAsset.Product2Id)){
							parentAccountIds.add(deletedAsset.AccountId);
						}
					}
				}

                if(!parentAccountIds.isEmpty()){
                    // GET MIN START DATE BY OPPORTUNITY FROM APPLICABLE LINE ITEMS
                    Map<Id, Date> minStartDateByAcct = new Map<Id, Date>();
                    for(AggregateResult result : [SELECT AccountId, MIN(Start_Date__c) minStart FROM Asset
                                                  WHERE AccountId IN :parentAccountIds AND Product2Id IN :CXGProductIds
                                                  GROUP BY AccountId]){

                        Id accountId = (Id)result.get('AccountId');
                        Date minStartDate = (Date)result.get('minStart');
                        minStartDateByAcct.put(accountId, minStartDate);
                    }

                    // GET OPPS TO UPDATE
                    List<Account> accountsToUpdate = new List<Account>();
                    for(Account parentAcct : [SELECT Id, CxG_Asset_Start_Date__c FROM Account WHERE Id IN :parentAccountIds]){
                        Date minStart = minStartDateByAcct.get(parentAcct.Id);

                        if(minStart == null && parentAcct.CxG_Asset_Start_Date__c != null){
                            parentAcct.CxG_Asset_Start_Date__c = null;
                            accountsToUpdate.add(parentAcct);
                        }
                        else if(minStart != null && minStart != parentAcct.CxG_Asset_Start_Date__c){
                            parentAcct.CxG_Asset_Start_Date__c = minStart;
                            accountsToUpdate.add(parentAcct);
                        }
                    }

                    // UPDATE ACCOUNTS
                    if(!accountsToUpdate.isEmpty()){
                        Database.saveResult[] acctResults = Database.update(accountsToUpdate, false);
                        SystemIssueLogHelper.CheckForDatabaseErrors(acctResults, 'AssetHelper', 'updateCxQDateOnParentAcct', true);
                    }
                }

                // END AUDIT IF ONE IS STARTED
                TriggerHelper.EndExecute('AssetHelper','updateCxQDateOnParentAcct');
            }
        }
        catch(Exception ex){
            SystemIssueLogHelper.LogException('AssetHelper', 'updateCxQDateOnParentAcct', (newOrUpdatedAssets == null ? outdatedOrDeletedAssets.values() : newOrUpdatedAssets), ex, true);
        }
    }







}