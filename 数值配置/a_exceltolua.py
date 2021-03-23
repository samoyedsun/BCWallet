# -*- coding: utf-8 -*-

import os
import xlrd
import re
import sys
# from imp import reload

# reload(sys)
# sys.setdefaultencoding("utf-8")

EXCEL_PATH = u'./'
DEFAULT_PATH = EXCEL_PATH + '/config'
CLIENT_PATH = DEFAULT_PATH + '/client'
SERVER_PATH = DEFAULT_PATH + '/server'

class OutPutGroupType:
    Null = 0 # 不导出
    Number = 1      # 数字 默认0
    String = 2      # 字符串 默认""
    Table = 3       # Lua表  默认{}
    KeyNumber = 4   # 数字key
    KeyString = 5   # 字符串key
    Native = 6      # 原样导出
    NumberOrNull = 7      # 数字 默认不导出
    StringOrNull = 8      # 字符串 默认不导出
    TableOrNull = 9      # 表 默认不导出

class OutPutType:
    All = 0 # 导出全部
    Client = 1 # 只导出客户端
    Server = 2 # 只导出服务端

def is_num(num):
	try:
		int(num)
		return True
	except ValueError:
		return False

def converInt(value):
	if is_num(value):
		if value == int(value):
			value = int(value)
	return value

def isNone(value):
	return value is None or str(value) == ""

def toString(value):
	if value is None:
		return ""
	return str(converInt(value))

def toFloat(value):
	if value is None:
		return 0
	try:
		float(value)
	except BaseException:
		print("value = %s" % value)
	value = float(value) * 100000 + 0.1
	if value > 0:
		value = int(value + 0.1) / 100000
	if value < 0:
		value = int(value - 0.1) / 100000
	return value

def toInt(value):
	if value is None:
		return 0
	try:
		float(value)
	except BaseException:
		print("value = %s" % value)
	intValue = int(float(value))
	floatValue = toFloat(value)
	if intValue != floatValue:
		return floatValue
	return intValue

def toNumString(value):
	if isNone(value):
		return "0"
	if type(value) is type(1.0):
		intValue = toInt(value)
		# if intValue == value:
		return str(intValue)
	return str(converInt(value))

class ConfigWriter:
	def __init__(self, path, tableName, type):
		self.path = path
		self.tableName = tableName
		self.type = type
		self.indexKey = {}
		self.canOutPutTable = True
		self.fd = None
		self.breakNum = 0

	def canDo(self, colIndex):
		if self.canCheck(colIndex):
			return toString(self.keyNameList[colIndex]) != "" and (toInt(self.outputType[colIndex]) == 0 or toInt(self.outputType[colIndex]) == self.type)

	def initHead(self):
		if not self.canOutPutTable:
			return

		self.fd = open(self.path + '/' + self.tableName + '.lua', 'w', encoding='utf-8')
		self.fd.write("-- " + self.excelName + " " + self.tableName + "\n")
		self.fd.write("--")
		for index in range(0, len(self.keyNameList)):
			if self.canDo(index):
				self.fd.write(" " + toString(self.keyNameList[index]) + ":" + toString(self.descList[index]) + " ")
		self.fd.write("\n")
		self.fd.write("local " + self.tableName + " = {\n")
		self.addBreak()

	def checkKey(self, key):
		if self.indexKey.get(key):
			raise Exception("表头重复: " + self.tableName + ".lua, 含有重复的键: " + key)
		else:
			self.indexKey[key] = 1

	def canCheck(self, index):
		if self.keyNameList[index] == "" or self.outputType[index] == "" or self.outputGroup[index] == "":
			return False

		return True

	def checkHead(self, keyNameList, descList, outputGroup, outputType):
		keyColIndex = None
		exceptStr = self.tableName + " 表头异常 请确定:\n第一行应为描述\n第二行应为字段名\n第三行应为导出类型\n第四行应为导出目标"
		if keyNameList is None or descList is None or outputType is None or outputGroup is None:
			raise Exception(exceptStr)

		for index in range(0, len(outputGroup)):
			if type(outputGroup[index]) is type(1.0):
				if outputGroup[index] == OutPutGroupType.KeyNumber or outputGroup[index] == OutPutGroupType.KeyString:
					keyColIndex = index

				if self.canCheck(index):
					if toInt(outputGroup[index]) < OutPutGroupType.Null or toInt(outputGroup[index]) > OutPutGroupType.TableOrNull:
						raise Exception(exceptStr)

		for index in range(0, len(outputType)):
			if type(outputType[index]) is type(1.0):
				if self.canCheck(index):
					if toInt(outputType[index]) < OutPutType.All or toInt(outputType[index]) > OutPutType.Server:
						raise Exception(exceptStr)
		for i in range(0, len(keyNameList) - 1):
			for j in range(i + 1, len(keyNameList)):
				if self.canCheck(i):
					if keyNameList[i] != "" and keyNameList[i] == keyNameList[j] :
						raise Exception("不能出现重复的导出字段 " + toString(keyNameList[i]))

		if (not keyColIndex is None) and (not self.canDo(keyColIndex)):
			self.canOutPutTable = False

	def open(self, excelName, keyNameList, descList, outputGroup, outputType):
		self.excelName = excelName
		self.keyNameList = keyNameList
		self.descList = descList
		self.outputType = outputType
		self.outputGroup = outputGroup
		self.checkHead(keyNameList, descList, outputGroup, outputType)
		self.initHead()

	def addBreak(self):
		self.breakNum = self.breakNum + 1

	def getLineBreak(self):
		breakStr = ""
		for num in range(self.breakNum):
			breakStr = breakStr + '\t'
		return breakStr

	def writeLine(self, lineValues):
		if not self.canOutPutTable:
			return
		if self.fd is None:
			return

		firstValue = lineValues[0]
		if isNone(firstValue) or firstValue == "":
			return

		if self.outputGroup[0] != "":
			if toInt(self.outputGroup[0]) == OutPutGroupType.KeyNumber:
				if isNone(firstValue):
					return
				self.checkKey(toString(firstValue))
				self.fd.write(self.getLineBreak() + "[" + toNumString(firstValue) + "] = {\n" )
				self.addBreak()
			elif toInt(self.outputGroup[0]) == OutPutGroupType.KeyString:
				if isNone(firstValue):
					return
				self.checkKey(toString(firstValue))
				self.fd.write(self.getLineBreak() + '[\"' + toString(firstValue) + '\"] = {\n' )
				self.addBreak()
			else:
				self.fd.write(self.getLineBreak() + "{\n")
				self.addBreak()
		else:
			self.fd.write(self.getLineBreak() + "{\n")
			self.addBreak()


		for colIndex in range(0, len(self.keyNameList)):
			keyValueStr = self.formatKeyValue(lineValues, colIndex)

			if keyValueStr != "":
				self.fd.write(self.getLineBreak() + keyValueStr + '\n')

		self.breakNum = 1
		self.fd.write(self.getLineBreak() + "},\n")

		

	def formatKeyValue(self, lineValues, colIndex):
		if not self.canDo(colIndex):
			return ""
		key = toString(self.keyNameList[colIndex])
		value = lineValues[colIndex]
		valueType = toInt(self.outputGroup[colIndex])
		if isNone(value):
			if valueType == OutPutGroupType.NumberOrNull or valueType == OutPutGroupType.StringOrNull or valueType == OutPutGroupType.TableOrNull:
				return ""
			if valueType == OutPutGroupType.Number or valueType == OutPutGroupType.KeyNumber:
				return key + " = 0,"
			if valueType == OutPutGroupType.String or valueType == OutPutGroupType.KeyString:
				return key + " = [[]],"
			if valueType == OutPutGroupType.Table:
				return key + " = {},"
			if valueType == OutPutGroupType.Native:
				return ","

		if valueType == OutPutGroupType.Number or valueType == OutPutGroupType.KeyNumber or valueType == OutPutGroupType.NumberOrNull or valueType == OutPutGroupType.Native:
			value = toNumString(value)
			return key + " = " + value + ","
		elif valueType == OutPutGroupType.String or valueType == OutPutGroupType.KeyString or valueType == OutPutGroupType.StringOrNull:
			value = toString(value)
			return key + " = [[" + value + "]],"
		else:
			return "%s = %s," % (key, value)
			# return key + " = " + value + ","

	def close(self):
		if self.fd:
			if self.canOutPutTable:
				self.fd.write("}\n\nreturn " + self.tableName)
			self.fd.close()

def analyzeExcel(sheet, tableName, excelName):
	nrows = sheet.nrows #行数
	if nrows <= 4:
		print(u'表少于4行无法导出')
		return
	
	descList = sheet.row_values(0)
	keyNameList = sheet.row_values(1)
	outputGroup = sheet.row_values(2)
	outputType = sheet.row_values(3)

	def getGroupNum():
		num = 0
		for index in range(0, len(outputGroup)):
			if (keyNameList[index] != "") and (outputType[index] != "") and (outputGroup[index] != ""):
				num = num + 1
		return num 

	def getGroupNumByType(oType):
		num = 0
		for value in outputType:
			if value == oType:
				num = num + 1

		return num

	justClient = False
	justServer = False

	if getGroupNumByType(OutPutType.Client) == getGroupNum():
		justClient = True

	if getGroupNumByType(OutPutType.Server) == getGroupNum():
		justServer = True

	def writeByType(oType):
		path = CLIENT_PATH
		if oType == OutPutType.Server:
			path = SERVER_PATH

		obj = ConfigWriter(path, tableName, oType)
		obj.open(excelName, keyNameList, descList, outputGroup, outputType)
		for rowIndex in range(4, nrows):
			obj.writeLine(sheet.row_values(rowIndex))

		obj.close()

	if not justServer:
		writeByType(OutPutType.Client)

	if not justClient:
		writeByType(OutPutType.Server)


def openExcel(file):
	print(u'打开配置表:'+file)
	data = xlrd.open_workbook(file)
	return data

def getTableName(sheetName):
	mm = re.findall("(\(.*?\))", sheetName)
	if(len(mm)>0):
		mm = mm[0]
		mm = mm.replace('[','').replace(']','')
		mm = mm.replace('(','').replace(')','')
		return mm
	else:
		return

# 转换为lua
def toLua(excelName):
	workbook = openExcel(excelName)
	if not workbook:
		print(u'配置表不存在:' + excelName)
		return

	for sheet in workbook.sheets():
		tableName = getTableName(sheet.name)
		if not tableName:
			continue

		analyzeExcel(sheet, tableName, excelName)



# 读取当前路径的配置表文件夹内的所有excel
def loadAllExcel():
	for fileName in os.listdir(EXCEL_PATH):
		if '~$' in fileName:
			continue

		if os.path.splitext(fileName)[1] == '.xlsx' :
			toLua(EXCEL_PATH + '/' + fileName)

# 检查文件夹是否存在，不存在则创建
def checkDir():
	if not os.path.exists(EXCEL_PATH):
		os.makedirs(EXCEL_PATH)

	if not os.path.exists(DEFAULT_PATH):
		os.makedirs(DEFAULT_PATH)

	if not os.path.exists(CLIENT_PATH):
		os.makedirs(CLIENT_PATH)

	if not os.path.exists(SERVER_PATH):
		os.makedirs(SERVER_PATH)

if __name__=="__main__":
	checkDir()
	loadAllExcel()
