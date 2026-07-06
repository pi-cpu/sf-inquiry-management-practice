// 問い合わせ種別マスタ(Inquiry_Category__c)とSLA目標時間マスタ(SLA_Target__c)の初期データ投入。
// SFDX: Execute Anonymous Apex with Editor Contents で実行する。再実行しても重複投入しない。

Map<String, String> categoryDescriptions = new Map<String, String>{
    '製品不良' => '製品の不具合・破損に関する問い合わせ',
    '使い方相談' => '製品・サービスの使用方法に関する問い合わせ',
    '契約関連' => '契約内容・請求・解約に関する問い合わせ',
    'クレーム' => '対応品質・サービスへの不満に関する問い合わせ'
};

Map<String, Map<String, Decimal>> targetHoursByCategory = new Map<String, Map<String, Decimal>>{
    '製品不良' => new Map<String, Decimal>{ 'High' => 4, 'Medium' => 8, 'Low' => 24 },
    '使い方相談' => new Map<String, Decimal>{ 'High' => 8, 'Medium' => 24, 'Low' => 48 },
    '契約関連' => new Map<String, Decimal>{ 'High' => 8, 'Medium' => 24, 'Low' => 48 },
    'クレーム' => new Map<String, Decimal>{ 'High' => 2, 'Medium' => 8, 'Low' => 24 }
};

Map<String, Inquiry_Category__c> existingCategories = new Map<String, Inquiry_Category__c>();
for (Inquiry_Category__c cat : [SELECT Id, Name FROM Inquiry_Category__c WHERE Name IN :categoryDescriptions.keySet()]) {
    existingCategories.put(cat.Name, cat);
}

List<Inquiry_Category__c> categoriesToInsert = new List<Inquiry_Category__c>();
for (String categoryName : categoryDescriptions.keySet()) {
    if (!existingCategories.containsKey(categoryName)) {
        categoriesToInsert.add(new Inquiry_Category__c(
            Name = categoryName,
            Description__c = categoryDescriptions.get(categoryName),
            Active__c = true
        ));
    }
}
if (!categoriesToInsert.isEmpty()) {
    insert categoriesToInsert;
    for (Inquiry_Category__c cat : categoriesToInsert) {
        existingCategories.put(cat.Name, cat);
    }
}

Set<Id> categoryIdsWithTargets = new Set<Id>();
for (SLA_Target__c t : [SELECT Inquiry_Category__c FROM SLA_Target__c WHERE Inquiry_Category__c IN :existingCategories.values()]) {
    categoryIdsWithTargets.add(t.Inquiry_Category__c);
}

List<SLA_Target__c> targetsToInsert = new List<SLA_Target__c>();
for (String categoryName : targetHoursByCategory.keySet()) {
    Inquiry_Category__c cat = existingCategories.get(categoryName);
    if (cat == null || categoryIdsWithTargets.contains(cat.Id)) {
        continue;
    }
    for (String priority : targetHoursByCategory.get(categoryName).keySet()) {
        targetsToInsert.add(new SLA_Target__c(
            Inquiry_Category__c = cat.Id,
            Priority__c = priority,
            Target_Hours__c = targetHoursByCategory.get(categoryName).get(priority)
        ));
    }
}
if (!targetsToInsert.isEmpty()) {
    insert targetsToInsert;
}

System.debug('問い合わせ種別マスタ 新規投入件数: ' + categoriesToInsert.size());
System.debug('SLA目標時間マスタ 新規投入件数: ' + targetsToInsert.size());
