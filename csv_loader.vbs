
Dim logDirectory, logstashSinceDbPath, logstashConfPath, logstashInputPath, logstashConfTemplatePath

logDirectory = "C:/Users/username/Desktop/logstash-multiple-csv-example/logs"
logstashSinceDbPath = "./.sincedb"
logstashConfPath = "C:/Users/username/Desktop/logstash-multiple-csv-example/conf"
logstashInputPath = "C:/Users/username/Desktop/logstash-multiple-csv-example/csv"
logstashConfTemplatePath = "./template.conf"

Class Index
    Private p_name
    Private p_fields
    Private p_documents

    Public Default Function Init(name, fields)
         p_name = name
         Set p_fields = CreateObject("System.Collections.ArrayList")
         Set p_fields = fields

         Set Init = Me
     End Function

    Public Property Get name()
        name = p_name
    End Property

    Public Property Get fields()
        Set fields = p_fields
    End Property

    Public Function getFieldsArrStr()
        Dim str
        str = "["
        For Each field in p_fields
            str = str + Chr(34) + field + Chr(34) + ","
        Next
        str = Left(str, Len(str) - 1) + "]"
        getFieldsArrStr = str
    End Function
End Class

'Logstash config file generation
Private Function generateLogstashConfig(ByVal indexDictionary)
    For each key in indexDictionary
        Dim fso, filePath, strText, strNewText
        Set fso = CreateObject("Scripting.FileSystemObject")
        filePath = logstashConfPath + "/" + indexDictionary.Item(key).name + ".conf"
        
        'Create file
        fso.CopyFile logstashConfTemplatePath, filePath

        'Get file content
        Set objFile = fso.OpenTextFile(filePath, 1)
        strText = objFile.ReadAll
        objFile.Close

        'Insert varaibles
        strNewText = strText
        strNewText = Replace(strNewText, "${tagName}", Chr(34) + indexDictionary.Item(key).name + Chr(34))
        strNewText = Replace(strNewText, "${inputSourcePath}", Chr(34) + logstashInputPath + "/" + indexDictionary.Item(key).name + ".csv" + Chr(34))
        strNewText = Replace(strNewText, "${sinceDbPath}", Chr(34) + logstashSinceDbPath + Chr(34))
        strNewText = Replace(strNewText, "${logstashLogPath}", Chr(34) + logDirectory + "/logstash_log.txt" + Chr(34))
        strNewText = Replace(strNewText, "${columnHeaders}", indexDictionary.Item(key).getFieldsArrStr())
        strNewText = Replace(strNewText, "${indexName}", Chr(34) + "idx_" + indexDictionary.Item(key).name + Chr(34))
        
        Set objFile = fso.OpenTextFile(filePath, 2)
        objFile.WriteLine strNewText
        objFile.Close
    Next
End Function

Private Function execute(ByVal indexDictionary)
    Dim filePath
    filePath = Replace(logstashConfPath,"/","\")
    Dim objShell
    Set objShell = WScript.CreateObject ("WScript.shell")
    objShell.run "cmd /c logstash -r -f" + filePath
    Set objShell = Nothing
End Function

Sub main ()
    Dim objFSO, indexDictionary

    Set objFSO = CreateObject("scripting.filesystemobject")  
    Set indexDictionary = CreateObject("Scripting.Dictionary")

    For Each oFile In objFSO.GetFolder(logstashInputPath).Files
        Dim csvFile, indexObj, fieldsStr, fieldArr, fields

        Set fields = CreateObject("System.Collections.ArrayList")
        Set csvFile = objFSO.OpenTextFile(oFile.Path, 1 , 1) 
        fieldsStr = csvFile.ReadLine

        'Trim and format fields
        fieldArr = Split(fieldsStr, ",")
        For Each field in fieldArr
            fields.Add field
        Next

        'Push index object for config file generation
        Set indexObj = (New Index)(Replace(oFile.Name, ".csv", ""), fields)
        indexDictionary.Add oFile.Name, indexObj
    Next

    Set objFSO = Nothing 

    generateLogstashConfig(indexDictionary)
    execute(indexDictionary)
End sub

main