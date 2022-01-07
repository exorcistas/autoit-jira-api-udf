#cs ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Name..................: JIRA_REST_API_Core
    Description...........: Core UDF for JIRA REST API
	Dependencies..........: JIRA General REST API
    Documentation.........: https://docs.atlassian.com/software/jira/docs/api/REST/latest/

    Author................: exorcistas@github.com
    Modified..............: 2021-05-14
    Version...............: v1.0.1.1
#ce ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#include-once
#include <BinaryCall.au3>
#include <Json.au3>
#include <Array.au3>

#Region GLOBAL_CONSTANTS

	;-- configure relevant values to match working environment:
	Global Const $_JIRA_BASE_URL = "https://jira.atlassian.com/"
	Global Const $_JIRA_BROWSE = $_JIRA_BASE_URL & "browse/"
	Global Const $_JIRA_REST_API = $_JIRA_BASE_URL & "rest/api/latest/"
	Global Const $_JIRA_REST_AGILE_BOARD = $_JIRA_BASE_URL & "rest/agile/latest/board/"
	Global Const $_JIRA_REST_JQL = $_JIRA_REST_API & "search?jql="
	Global Const $_JIRA_REST_ISSUE = $_JIRA_REST_API & "issue/"

    ;-- default issue types:
	Global Const $_JIRA_ISSUETYPE_EPIC = "Epic"
	Global Const $_JIRA_ISSUETYPE_TASK = "Task"
	Global Const $_JIRA_ISSUETYPE_BUG = "Bug"
    Global Const $_JIRA_ISSUETYPE_STORY = "Story"

#EndRegion GLOBAL_CONSTANTS

#Region GLOBAL_VARS
	Global $_HTTP_STATUS = 0
	Global $_HTTP_RESPONSE = ""

	Global $_JIRA_DEBUG = True
#EndRegion GLOBAL_VARS


#Region FUNCTIONS_LIST
#cs	===================================================================================================================================
%% CORE %%
	_JIRA_SetAuthCredentials($_xPassword, $_sUserID = @UserName)
    _JIRA_CreateIssue($_sJSON, $_sAuthCredentials_b64)
    _JIRA_GetIssue($_sIssueID, $_sAuthCredentials_b64)
    _JIRA_AssignIssue($_sIssueID, $_sAssigneeID, $_sAuthCredentials_b64)
    _JIRA_GetIssueComments($_sIssueID, $_sAuthCredentials_b64)
	_JIRA_AddIssueComment($_sIssueID, $_sComment, $_sAuthCredentials_b64)
	_JIRA_DeleteIssue($_sIssueID, $_sAuthCredentials_b64)
	_JIRA_EditIssue($_sIssueID, $_sJSONRequest, $_sAuthCredentials_b64)
	_JIRA_EditIssueField($_sIssueID, $_sFieldName, $_sSetValue, $_sAuthCredentials_b64, $_sParameter = "")
    _JIRA_AddIssueAttachment($_FileData, $_sIssueID, $_sAuthCredentials_b64)
    _JIRA_QueryJQL($_sJQLQuery, $_sAuthCredentials_b64)
    _JIRA_GetIssueFields($_sIssueID, $_sSelectFields, $_sAuthCredentials_b64)
    _JIRA_GetProjectSprints($_sProjectRapidViewID, $_sAuthCredentials_b64, $_bActiveOnly = True)
	_JIRA_PerformTransition($_sIssueID, $_sTransitionId, $_sAuthCredentials_b64)

%% INTERNAL %%
	__JIRA_GET_REQUEST($_sRequestURL, $_sAuthCredentials_b64)
	__JIRA_POST_REQUEST($_sPostData, $_sRequestURL, $_sAuthCredentials_b64, $_bIsFile = False)
	__JIRA_PUT_REQUEST($_sPutData, $_sRequestURL, $_sAuthCredentials_b64)
	__JIRA_DELETE_REQUEST($_sRequestURL, $_sAuthCredentials_b64)
    __JIRA_decodeSprints($_sJSON)
    __JIRA_decodeIssueID($_sJSON)
	__JIRA_getJSONValue($_sJSON, $_sSearchValue)
	__JIRA_convertFileToData($_sFilePath)
	__JIRA_base64($vCode, $bEncode = True, $bUrl = False)
#ce	===================================================================================================================================
#EndRegion FUNCTIONS_LIST


#Region CORE_FUNCTIONS

    #cs #FUNCTION# ====================================================================================================================
        Name...........: _JIRA_SetAuthCredentials($_xPassword, $_sUserID = @UserName)
        Description ...: Creates base64 authentication string to use with REST API http requests.
        Syntax.........: -

		Parameters.....: $_xPassword:	Password
						 $_sUserID:		User ID

        Return values..: $_sAuthCredentials_b64:	Base64 credential string

        Author ........: exorcistas@github.com
        Modified.......: 2020-03-23
    #ce ===============================================================================================================================
    Func _JIRA_SetAuthCredentials($_xPassword, $_sUserID = @UserName)
        ;-- convert username & password to Base64 type (string)
		Local $_sAuthCredentials_b64 = __JIRA_base64($_sUserID & ":" & $_xPassword)
		$_xPassword = ""	;-- clear password variable

		Return $_sAuthCredentials_b64
    EndFunc

	#cs #FUNCTION# ====================================================================================================================
        Name...........: _JIRA_CreateIssue($_sJSON, $_sAuthCredentials_b64)
        Description ...: Creates an issue or a sub-task from a JSON representation.
        Syntax.........: POST /rest/api/2/issue

		Parameters.....: $_sJSON:					JSON to post issue fields
						 $_sAuthCredentials_b64:	authentication string

        Return values..: raw http response

        Author ........: exorcistas@github.com
        Modified.......: 2020-03-23
    #ce ===============================================================================================================================
    Func _JIRA_CreateIssue($_sJSON, $_sAuthCredentials_b64)
        Local $_sResponse = __JIRA_POST_REQUEST($_sJSON, $_JIRA_REST_ISSUE, $_sAuthCredentials_b64, False)

        Return SetError(@error, @extended, $_sResponse)
    EndFunc

	#cs #FUNCTION# ====================================================================================================================
        Name...........: _JIRA_GetIssue($_sIssueID, $_sAuthCredentials_b64)
        Description ...: Returns a full representation of the issue for the given issue key.
						 An issue JSON consists of the issue key, a collection of fields, a link to the workflow transition sub-resource,
						 and (optionally) the HTML rendered values of any fields that support it
						 (e.g. if wiki syntax is enabled for the description or comments).
						 The fields param (which can be specified multiple times) gives a comma-separated list of fields to include in the response.
						 This can be used to retrieve a subset of fields.
						 A particular field can be excluded by prefixing it with a minus.
						 By default, all (*all) fields are returned in this get-issue resource. See documentation for more info.
						 Note: the default is different when doing a jql search -- the default there is just navigable fields (*navigable).

        Syntax.........: GET /rest/api/2/issue/{issueIdOrKey}

		Parameters.....: $_sIssueID:				issue ID
						 $_sAuthCredentials_b64:	authentication string

        Return values..: raw http response

        Author ........: exorcistas@github.com
        Modified.......: 2020-03-23
    #ce ===============================================================================================================================
    Func _JIRA_GetIssue($_sIssueID, $_sAuthCredentials_b64)
        Local $_sResponse = __JIRA_GET_REQUEST($_JIRA_REST_ISSUE & $_sIssueID, $_sAuthCredentials_b64)

        Return SetError(@error, @extended, $_sResponse)
    EndFunc

	#cs #FUNCTION# ====================================================================================================================
        Name...........: _JIRA_AssignIssue($_sIssueID, $_sAssigneeID, $_sAuthCredentials_b64)
		Description ...: Assigns an issue to a user.
						 You can use this resource to assign issues when the user submitting the request has the assign permission
						 but not the edit issue permission.
						 If the name is "-1" automatic assignee is used.
						 A null name will remove the assignee.

        Syntax.........: PUT /rest/api/2/issue/{issueIdOrKey}/assignee

		Parameters.....: $_sIssueID:				issue ID
						 $_sAssigneeID:				assignee user S-ID
						 $_sAuthCredentials_b64:	authentication string

        Return values..: raw http response

        Author ........: exorcistas@github.com
        Modified.......: 2020-03-23
    #ce ===============================================================================================================================
	Func _JIRA_AssignIssue($_sIssueID, $_sAssigneeID, $_sAuthCredentials_b64)
		Local $_sRequest = StringReplace("{'name': '" & $_sAssigneeID & "'}", "'", Chr(34))
		Local $_sResponse = __JIRA_PUT_REQUEST($_sRequest, $_JIRA_REST_ISSUE & $_sIssueID & "/assignee", $_sAuthCredentials_b64)

		Return SetError(@error, @extended, $_sResponse)
    EndFunc

	#cs #FUNCTION# ====================================================================================================================
        Name...........: _JIRA_GetIssueComments($_sIssueID, $_sAuthCredentials_b64)
		Description ...: Returns all comments for an issue.
						 Results can be ordered by the "created" field which means the date a comment was added.

        Syntax.........: GET /rest/api/2/issue/{issueIdOrKey}/comment

		Parameters.....: $_sIssueID:				issue ID
						 $_sAuthCredentials_b64:	authentication string

        Return values..: raw http response

        Author ........: exorcistas@github.com
        Modified.......: 2020-03-23
    #ce ===============================================================================================================================
    Func _JIRA_GetIssueComments($_sIssueID, $_sAuthCredentials_b64)
        Local $_sResponse = __JIRA_GET_REQUEST($_JIRA_REST_ISSUE & $_sIssueID & "/comment", $_sAuthCredentials_b64)

        Return SetError(@error, @extended, $_sResponse)
    EndFunc

	#cs #FUNCTION# ====================================================================================================================
        Name...........: _JIRA_AddIssueComment($_sIssueID, $_sComment, $_sAuthCredentials_b64)
		Description ...: Adds a new comment to an issue.

        Syntax.........: POST /rest/api/2/issue/{issueIdOrKey}/comment

		Parameters.....: $_sIssueID:				issue ID
						 $_sComment:				comment body text. string must respect formatting of API
						 $_sAuthCredentials_b64:	authentication string

        Return values..: raw http response

        Author ........: exorcistas@github.com
        Modified.......: 2020-03-23
    #ce ===============================================================================================================================
	Func _JIRA_AddIssueComment($_sIssueID, $_sComment, $_sAuthCredentials_b64)
		Local $_sRequest = StringReplace("{'body': '" & $_sComment & "'}", "'", Chr(34))
        Local $_sResponse = __JIRA_POST_REQUEST($_sRequest, $_JIRA_REST_ISSUE & $_sIssueID & "/comment", $_sAuthCredentials_b64, False)

        Return SetError(@error, @extended, $_sResponse)
    EndFunc

	#cs #FUNCTION# ====================================================================================================================
        Name...........: _JIRA_DeleteIssue($_sIssueID, $_sAuthCredentials_b64)
		Description ...: Delete an issue.
						 If the issue has subtasks you must set the parameter deleteSubtasks=true to delete the issue.
						 You cannot delete an issue without its subtasks also being deleted.

        Syntax.........: DELETE /rest/api/2/issue/{issueIdOrKey}

		Parameters.....: $_sIssueID:				issue ID
						 $_sAuthCredentials_b64:	authentication string

        Return values..: raw http response

        Author ........: exorcistas@github.com
        Modified.......: 2020-03-23
    #ce ===============================================================================================================================
    Func _JIRA_DeleteIssue($_sIssueID, $_sAuthCredentials_b64)
		Local $_sResponse = __JIRA_DELETE_REQUEST($_JIRA_REST_ISSUE & $_sIssueID, $_sAuthCredentials_b64)

		Return SetError(@error, @extended, $_sResponse)
    EndFunc

	#cs #FUNCTION# ====================================================================================================================
        Name...........: _JIRA_EditIssue($_sIssueID, $_sJSONRequest, $_sAuthCredentials_b64)
		Description ...: Edits an issue from a JSON representation.
						 The issue can either be updated by setting explicit the field value(s) or by using an operation to change the field value.
						 The fields that can be updated, in either the fields parameter or the update parameter, can be determined using the /rest/api/2/issue/{issueIdOrKey}/editmeta resource.
						 If a field is not configured to appear on the edit screen, then it will not be in the editmeta, and a field validation error will occur if it is submitted.
						 Specifying a "field_id": field_value in the "fields" is a shorthand for a "set" operation in the "update" section.
						 Field should appear either in "fields" or "update", not in both.

        Syntax.........: PUT /rest/api/2/issue/{issueIdOrKey}

		Parameters.....: $_sIssueID:				issue ID
						 $_sJSONRequest:			JSON of issue fields to edit
						 $_sAuthCredentials_b64:	authentication string

        Return values..: raw http response

        Author ........: exorcistas@github.com
        Modified.......: 2020-03-23
    #ce ===============================================================================================================================
    Func _JIRA_EditIssue($_sIssueID, $_sJSONRequest, $_sAuthCredentials_b64)
		Local $_sResponse = __JIRA_PUT_REQUEST($_sJSONRequest, $_JIRA_REST_ISSUE & $_sIssueID, $_sAuthCredentials_b64)

		Return SetError(@error, @extended, $_sResponse)
	EndFunc

	#cs #FUNCTION# ====================================================================================================================
        Name...........: _JIRA_EditIssueField($_sIssueID, $_sFieldName, $_sSetValue, $_sAuthCredentials_b64, $_sParameter = "")
		Description ...: Edits a single issue field.

        Syntax.........: PUT /rest/api/2/issue/{issueIdOrKey}

		Parameters.....: $_sIssueID:				issue ID
						 $_sFieldName:				field name
						 $_sSetValue:				value to set
						 $_sParameter:				optional parameter (some fields require)
						 $_sAuthCredentials_b64:	authentication string

        Return values..: raw http response

        Author ........: exorcistas@github.com
        Modified.......: 2020-03-23
    #ce ===============================================================================================================================
	Func _JIRA_EditIssueField($_sIssueID, $_sFieldName, $_sSetValue, $_sAuthCredentials_b64, $_sParameter = "")
		$_sSetValue = ($_sSetValue = "null") ? "null" : Chr(34) & $_sSetValue & Chr(34)	;-- NULL value requires to be passed without quotes
		Local $_sRequestWithParameter = StringReplace("{'fields': {'" & $_sFieldName & "': " & $_sSetValue & "}}", "'", Chr(34))
		Local $_sRequestWithoutParam = StringReplace("{'fields': {'" & $_sFieldName & "': {'" & $_sParameter & "': " & $_sSetValue & "}}}", "'", Chr(34))

		Local $_sJSONRequest = ($_sParameter = "") ? $_sRequestWithoutParam : $_sRequestWithParameter
		Local $_sResponse = _JIRA_EditIssue($_sIssueID, $_sJSONRequest, $_sAuthCredentials_b64)

		Return SetError(@error, @extended, $_sResponse)
    EndFunc

	#cs #FUNCTION# ====================================================================================================================
        Name...........: _JIRA_AddIssueAttachment($_sFilePath, $_sIssueID, $_sAuthCredentials_b64)
		Description ...: Add one attachment to an issue.
						 This resource expects a multipart post. The media-type multipart/form-data is defined in RFC 1867. Most client libraries have classes that make dealing with multipart posts simple. For instance, in Java the Apache HTTP Components library provides a MultiPartEntity that makes it simple to submit a multipart POST.
						 In order to protect against XSRF attacks, because this method accepts multipart/form-data, it has XSRF protection on it. This means you must submit a header of X-Atlassian-Token: no-check with the request, otherwise it will be blocked.
						 The name of the multipart/form-data parameter that contains attachments must be "file"

        Syntax.........: POST /rest/api/2/issue/{issueIdOrKey}/attachments

		Parameters.....: $_sIssueID:				issue ID
						 $_sFilePath:				full path to file
						 $_sAuthCredentials_b64:	authentication string

        Return values..: raw http response

        Author ........: exorcistas@github.com
        Modified.......: 2020-03-23
    #ce ===============================================================================================================================
	Func _JIRA_AddIssueAttachment($_sFilePath, $_sIssueID, $_sAuthCredentials_b64)
		Local $_FileData = __JIRA_convertFileToData($_sFilePath)
        Local $_sResponse = __JIRA_POST_REQUEST($_FileData, $_JIRA_REST_ISSUE & $_sIssueID & "/attachments", $_sAuthCredentials_b64, True)

        Return SetError(@error, @extended, $_sResponse)
    EndFunc

	#cs #FUNCTION# ====================================================================================================================
        Name...........: _JIRA_QueryJQL($_sJQLQuery, $_sAuthCredentials_b64)
		Description ...: Search JIRA issues with selected parameters

        Syntax.........: https://support.atlassian.com/jira-software-cloud/docs/what-is-advanced-searching-in-jira-cloud/

		Parameters.....: $_sJQLQuery:				JQL query search parameters
						 $_sAuthCredentials_b64:	authentication string

        Return values..: raw http response

        Author ........: exorcistas@github.com
        Modified.......: 2020-03-23
    #ce ===============================================================================================================================
    Func _JIRA_QueryJQL($_sJQLQuery, $_sAuthCredentials_b64)
		Local $_sResponse = __JIRA_GET_REQUEST($_JIRA_REST_JQL & $_sJQLQuery, $_sAuthCredentials_b64)

		Return SetError(@error, @extended, $_sResponse)
    EndFunc

	#cs #FUNCTION# ====================================================================================================================
        Name...........: _JIRA_GetIssueFields($_sIssueID, $_sSelectFields, $_sAuthCredentials_b64)
		Description ...: Selects specified issue fields

        Syntax.........: -

		Parameters.....: $_sIssueID:				issue ID
						 $_sSelectFields:			fieldnames to select
						 $_sAuthCredentials_b64:	authentication string

        Return values..: raw http response

        Author ........: exorcistas@github.com
        Modified.......: 2020-03-23
    #ce ===============================================================================================================================
    Func _JIRA_GetIssueFields($_sIssueID, $_sSelectFields, $_sAuthCredentials_b64)
        Local $_sResponse = __JIRA_GET_REQUEST($_JIRA_REST_ISSUE & $_sIssueID & "?&fields=" & $_sSelectFields, $_sAuthCredentials_b64)

        Return SetError(@error, @extended, $_sResponse)
    EndFunc

	#cs #FUNCTION# ====================================================================================================================
        Name...........: _JIRA_GetProjectSprints($_sProjectRapidViewID, $_sAuthCredentials_b64, $_bActiveOnly = True)
		Description ...: Gets specific project sprints (default - active only)

        Syntax.........: -

		Parameters.....: $_sProjectRapidViewID:		project ID number from RapidView
						 $_sAuthCredentials_b64:	authentication string

        Return values..: raw http response

        Author ........: exorcistas@github.com
        Modified.......: 2020-03-23
    #ce ===============================================================================================================================
    Func _JIRA_GetProjectSprints($_sProjectRapidViewID, $_sAuthCredentials_b64, $_bActiveOnly = True)
        Local $_sQuery = ($_bActiveOnly) ? "?state=active" : ""
        Local $_sResponse = __JIRA_GET_REQUEST($_JIRA_REST_AGILE_BOARD & $_sProjectRapidViewID & "/sprint" & $_sQuery, $_sAuthCredentials_b64)

        Return SetError(@error, @extended, $_sResponse)
    EndFunc

	#cs #FUNCTION# ====================================================================================================================
        Name...........: _JIRA_PerformTransition($_sIssueID, $_sTransitionId, $_sAuthCredentials_b64)
		Description ...: Performs a transition that is stated in workflow of issue type of $_sIssueID.

        Syntax.........: -

		Parameters.....: $_sIssueID:		Issue ID string
						 $_sTransitionId:  Transition ID in the workflow
						 $_sAuthCredentials_b64:	authentication string

        Return values..: raw http response

        Author ........: exorcistas@github.com
        Modified.......: 2021-03-16
    #ce ===============================================================================================================================
	Func _JIRA_PerformTransition($_sIssueID, $_sTransitionId, $_sAuthCredentials_b64)
		Local $_sRequest =  StringReplace("{'transition': {'id': '" & $_sTransitionId & "'}}", "'", Chr(34))
		Local $_sResponse = __JIRA_POST_REQUEST($_sRequest, $_JIRA_REST_ISSUE & $_sIssueID & "/transitions", $_sAuthCredentials_b64, False)

		Return SetError(@error, @extended, $_sResponse)
	EndFunc

#EndRegion CORE_FUNCTIONS


#Region INTERNAL_FUNCTIONS

	Func __JIRA_GET_REQUEST($_sRequestURL, $_sAuthCredentials_b64)

		;-- create a HTTP COM object
		Local $oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
			If @error Then Return SetError(1, @error, False)

        With $oHTTP
            ;-- open GET method request
			.Open("GET", $_sRequestURL, False)

			.SetRequestHeader("Authorization", "Basic " & $_sAuthCredentials_b64)		;-- set authorization header
			.SetRequestHeader("Content-Type", "application/json")			;-- set content type header

			;-- send request
			.Send()
				If @error Then Return SetError(2, @error, False)

			;-- get status code and response:
			$_HTTP_STATUS = .Status
			$_HTTP_RESPONSE = .ResponseText

            ;-- close HTTP connection
			.Close()
		EndWith

		If $_JIRA_DEBUG Then
			ConsoleWrite(@CRLF & "[__JIRA_GET_REQUEST]:	" & $_sRequestURL & @CRLF & _
						"HTTP Status:	" & String($_HTTP_STATUS) & @CRLF & _
						"HTTP Response:	" & @CRLF & $_HTTP_RESPONSE & @CRLF)
		EndIf

			If ($_HTTP_STATUS <> 200) Then SetError(3)
		Return SetError(@error, $_HTTP_STATUS, $_HTTP_RESPONSE)
	EndFunc

	Func __JIRA_POST_REQUEST($_sPostData, $_sRequestURL, $_sAuthCredentials_b64, $_bIsFile = False)

		;-- create a HTTP COM object
		Local $oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
			If @error Then Return SetError(1, @error, False)

		With $oHTTP
			;-- open POST method request
			.Open("POST", $_sRequestURL, False)

			;-- set authorization header
			.SetRequestHeader("Authorization", "Basic " & $_sAuthCredentials_b64)

			;-- set different headers if POST FILE
			If $_bIsFile Then
				Local $_sBoundary = "--------Boundary"
				.SetRequestHeader("X-Atlassian-Token", "no-check")
				.SetRequestHeader("Content-Type", "multipart/form-data; " & "boundary=" & $_sBoundary)
			Else
				;-- set content type header: JSON
				.SetRequestHeader("Content-Type", "application/json")
			EndIf

			;-- send request
			.Send($_sPostData)
				If @error Then Return SetError(2, @error, False)

			;-- get status code and response
			$_HTTP_STATUS = .Status
			$_HTTP_RESPONSE = .ResponseText

			.Close()
		EndWith

		If $_JIRA_DEBUG Then
			ConsoleWrite(@CRLF & "[__JIRA_POST_REQUEST]:	" & $_sRequestURL & @CRLF & _
							"IsFile:	" & $_bIsFile & @CRLF & _
							"Post Data:	" & $_sPostData & @CRLF & _
							"HTTP Status:	" & String($_HTTP_STATUS) & @CRLF & _
							"HTTP Response:	" & @CRLF & $_HTTP_RESPONSE & @CRLF)
		EndIf

			If $_HTTP_STATUS <> 200 OR $_HTTP_STATUS <> 201 Then SetError(3)
		Return SetError(@error, $_HTTP_STATUS, $_HTTP_RESPONSE)
	EndFunc

	Func __JIRA_PUT_REQUEST($_sPutData, $_sRequestURL, $_sAuthCredentials_b64)

		;-- create a HTTP COM object
		Local $oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
			If @error Then Return SetError(1, @error, False)

        With $oHTTP
            ;-- open PUT method request
			.Open("PUT", $_sRequestURL, False)

			.SetRequestHeader("Authorization", "Basic " & $_sAuthCredentials_b64)		;-- set authorization header
			.SetRequestHeader("Content-Type", "application/json")			;-- set content type header

			;-- send request
			.Send($_sPutData)
				If @error Then Return SetError(2, @error, False)

			;-- get status code and response:
			$_HTTP_STATUS = .Status
			$_HTTP_RESPONSE = .ResponseText

            ;-- close HTTP connection
			.Close()
		EndWith

		If $_JIRA_DEBUG Then
			ConsoleWrite(@CRLF & "[__JIRA_PUT_REQUEST]:	" & $_sRequestURL & @CRLF & _
						"HTTP Status:	" & String($_HTTP_STATUS) & @CRLF & _
						"HTTP Response:	" & @CRLF & $_HTTP_RESPONSE & @CRLF)
		EndIf

			If ( ($_HTTP_STATUS <> 200) OR ($_HTTP_STATUS <> 201) OR ($_HTTP_STATUS <> 204) ) Then SetError(3)
		Return SetError(@error, $_HTTP_STATUS, $_HTTP_RESPONSE)
	EndFunc

	Func __JIRA_DELETE_REQUEST($_sRequestURL, $_sAuthCredentials_b64)

		;-- create a HTTP COM object
		Local $oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
			If @error Then Return SetError(1, @error, False)

        With $oHTTP
            ;-- open DELETE method request
			.Open("DELETE", $_sRequestURL, False)

			.SetRequestHeader("Authorization", "Basic " & $_sAuthCredentials_b64)		;-- set authorization header
			.SetRequestHeader("Content-Type", "application/json")			;-- set content type header

			;-- send request
			.Send()
				If @error Then Return SetError(2, @error, False)

			;-- get status code and response:
			$_HTTP_STATUS = .Status
			$_HTTP_RESPONSE = .ResponseText

            ;-- close HTTP connection
			.Close()
		EndWith

		If $_JIRA_DEBUG Then
			ConsoleWrite(@CRLF & "[__JIRA_DELETE_REQUEST]:	" & $_sRequestURL & @CRLF & _
						"HTTP Status:	" & String($_HTTP_STATUS) & @CRLF & _
						"HTTP Response:	" & @CRLF & $_HTTP_RESPONSE & @CRLF)
		EndIf

			If ( ($_HTTP_STATUS <> 200) OR ($_HTTP_STATUS <> 201) OR ($_HTTP_STATUS <> 204) ) Then SetError(3)
		Return SetError(@error, $_HTTP_STATUS, $_HTTP_RESPONSE)
	EndFunc

	Func __JIRA_decodeSprints($_sJSON)
		Local $_oValues = __JIRA_getJSONValue($_sJSON, "[values]")
		Local $_aSprints[0][2]

		If UBound($_oValues) > 0 Then
			For $_value In $_oValues
				_ArrayAdd($_aSprints, Json_Get($_value, "[name]") & "|" & Json_Get($_value, "[id]"))
			Next
		EndIf

		Return $_aSprints
	EndFunc

	Func __JIRA_decodeIssueID($_sJSON)
		Local $_sIssueID = __JIRA_getJSONValue($_sJSON, "[key]")
		Return $_sIssueID
	EndFunc

	Func __JIRA_getJSONValue($_sJSON, $_sKeyName)
		Local $_oJson = Json_Decode($_sJSON)
		Local $_sValue = Json_Get($_oJson, $_sKeyName)

		Return $_sValue
	EndFunc

	Func __JIRA_convertFileToData($_sFilePath)
		Local $_sFilename = StringSplit($_sFilePath,"\")
		$_sFilename = $_sFilename[(Ubound($_sFilename)-1)]

		Local $_sBoundary = "--------Boundary"
		Local $_postData = "--" & $_sBoundary & @CRLF & _
							"Content-Disposition: form-data; name=" & Chr(34) & "file" & Chr(34) & "; filename=" & Chr(34) & $_sFilename & Chr(34) & @CRLF & _
							"Content-Type: application/octet-stream" & @CRLF & @CRLF & _
							Fileread($_sFilePath) & @CRLF & _
							"--" & $_sBoundary & "--" & @CRLF

		Return $_postData
	EndFunc

	#cs ==============================================================================================================================
		Function:		base64($vCode [, $bEncode = True [, $bUrl = False]])

		Description:	Decode or Encode $vData using Microsoft.XMLDOM to Base64Binary or Base64Url.
	                   	IMPORTANT! Encoded base64url is without @LF after 72 lines. Some websites may require this.

		Parameter(s):   $vData      - string or integer | Data to encode or decode.
	                	$bEncode    - boolean           | True - encode, False - decode.
	                   	$bUrl       - boolean           | True - output is will decoded or encoded using base64url shema.

		Return Value(s):	On Success - Returns output data
	                   		On Failure - Returns 1 - Failed to create object.

		Author (s):			(Ghads on Wordpress.com), Ascer
	#ce ===============================================================================================================================
	Func __JIRA_base64($vCode, $bEncode = True, $bUrl = False)
		Local $oDM = ObjCreate("Microsoft.XMLDOM")
		If Not IsObj($oDM) Then Return SetError(1, 0, 1)
		Local $oEL = $oDM.createElement("Tmp")
		$oEL.DataType = "bin.base64"
		If $bEncode then
			$oEL.NodeTypedValue = Binary($vCode)
			If Not $bUrl Then Return $oEL.Text
			Return StringReplace(StringReplace(StringReplace($oEL.Text, "+", "-"),"/", "_"), @LF, "")
		Else
			If $bUrl Then $vCode = StringReplace(StringReplace($vCode, "-", "+"), "_", "/")
			$oEL.Text = $vCode
			Return $oEL.NodeTypedValue
		EndIf
    EndFunc ;==>base64
#EndRegion INTERNAL_FUNCTIONS