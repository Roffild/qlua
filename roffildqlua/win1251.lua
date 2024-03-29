--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- https://github.com/Roffild/qlua
--

local roffild_win1251 = {}

function roffild_win1251.getParamExAll()
    return {
        STATUS = {type = "STRING", desc = "������"},
        LOTSIZE = {type = "NUMERIC", desc = "������ ����"},
        BID = {type = "NUMERIC", desc = "������ ���� ������"},
        BIDDEPTH = {type = "NUMERIC", desc = "����� �� ������ ����"},
        BIDDEPTHT = {type = "NUMERIC", desc = "��������� �����"},
        NUMBIDS = {type = "NUMERIC", desc = "���������� ������ �� �������"},
        OFFER = {type = "NUMERIC", desc = "������ ���� �����������"},
        OFFERDEPTH = {type = "NUMERIC", desc = "����������� �� ������ ����"},
        OFFERDEPTHT = {type = "NUMERIC", desc = "��������� �����������"},
        NUMOFFERS = {type = "NUMERIC", desc = "���������� ������ �� �������"},
        OPEN = {type = "NUMERIC", desc = "���� ��������"},
        HIGH = {type = "NUMERIC", desc = "������������ ���� ������"},
        LOW = {type = "NUMERIC", desc = "����������� ���� ������"},
        LAST = {type = "NUMERIC", desc = "���� ��������� ������"},
        CHANGE = {type = "NUMERIC", desc = "������� ���� ��������� � ���������� ������"},
        QTY = {type = "NUMERIC", desc = "���������� ������������ � ��������� ������"},
        TIME = {type = "STRING", desc = "����� ��������� ������"},
        VOLTODAY = {type = "NUMERIC", desc = "���������� ������������ � ������������ �������"},
        VALTODAY = {type = "NUMERIC", desc = "������ � �������"},
        TRADINGSTATUS = {type = "STRING", desc = "��������� ������"},
        VALUE = {type = "NUMERIC", desc = "������ � ������� ��������� ������"},
        WAPRICE = {type = "NUMERIC", desc = "���������������� ����"},
        HIGHBID = {type = "NUMERIC", desc = "������ ���� ������ �������"},
        LOWOFFER = {type = "NUMERIC", desc = "������ ���� ����������� �������"},
        NUMTRADES = {type = "NUMERIC", desc = "���������� ������ �� �������"},
        PREVPRICE = {type = "NUMERIC", desc = "���� ��������"},
        PREVWAPRICE = {type = "NUMERIC", desc = "���������� ������"},
        CLOSEPRICE = {type = "NUMERIC", desc = "���� ������� ��������"},
        LASTCHANGE = {type = "NUMERIC", desc = "% ��������� �� ��������"},
        PRIMARYDIST = {type = "STRING", desc = "����������"},
        ACCRUEDINT = {type = "NUMERIC", desc = "����������� �������� �����"},
        YIELD = {type = "NUMERIC", desc = "���������� ��������� ������"},
        COUPONVALUE = {type = "NUMERIC", desc = "������ ������"},
        YIELDATPREVWAPRI = {type = "NUMERIC", desc = "���������� �� ���������� ������"},
        YIELDATWAPRICE = {type = "NUMERIC", desc = "���������� �� ������"},
        PRICEMINUSPREVWAPRICE = {type = "NUMERIC", desc = "������� ���� ��������� � ���������� ������"},
        CLOSEYIELD = {type = "NUMERIC", desc = "���������� ��������"},
        CURRENTVALUE = {type = "NUMERIC", desc = "������� �������� �������� ���������� �����"},
        LASTVALUE = {type = "NUMERIC", desc = "�������� �������� ���������� ����� �� �������� ����������� ���"},
        LASTTOPREVSTLPRC = {type = "NUMERIC", desc = "������� ���� ��������� � ���������� ������"},
        PREVSETTLEPRICE = {type = "NUMERIC", desc = "���������� ��������� ����"},
        PRICEMVTLIMIT = {type = "NUMERIC", desc = "����� ��������� ����"},
        PRICEMVTLIMITT1 = {type = "NUMERIC", desc = "����� ��������� ���� T1"},
        MAXOUTVOLUME = {type = "NUMERIC", desc = "����� ������ �������� ������ (� ����������)"},
        PRICEMAX = {type = "NUMERIC", desc = "����������� ��������� ����"},
        PRICEMIN = {type = "NUMERIC", desc = "���������� ��������� ����"},
        NEGVALTODAY = {type = "NUMERIC", desc = "������ ������������ � �������"},
        NEGNUMTRADES = {type = "NUMERIC", desc = "���������� ������������ ������ �� �������"},
        NUMCONTRACTS = {type = "NUMERIC", desc = "���������� �������� �������"},
        CLOSETIME = {type = "STRING", desc = "����� �������� ���������� ������ (��� �������� ���)"},
        OPENVAL = {type = "NUMERIC", desc = "�������� ������� ��� �� ������ �������� ������"},
        CHNGOPEN = {type = "NUMERIC", desc = "��������� �������� ������� ��� �� ��������� �� ��������� ��������"},
        CHNGCLOSE = {type = "NUMERIC", desc = "��������� �������� ������� ��� �� ��������� �� ��������� ��������"},
        BUYDEPO = {type = "NUMERIC", desc = "����������� ����������� ��������"},
        SELLDEPO = {type = "NUMERIC", desc = "����������� ����������� ����������"},
        CHANGETIME = {type = "STRING", desc = "����� ���������� ���������"},
        SELLPROFIT = {type = "NUMERIC", desc = "���������� �������"},
        BUYPROFIT = {type = "NUMERIC", desc = "���������� �������"},
        TRADECHANGE = {type = "NUMERIC", desc = "������� ���� ��������� � ���������� ������ (FORTS, �� ���, ����)"},
        FACEVALUE = {type = "NUMERIC", desc = "������� (��� ������������ ����)"},
        MARKETPRICE = {type = "NUMERIC", desc = "�������� ���� �����"},
        MARKETPRICETODAY = {type = "NUMERIC", desc = "�������� ����"},
        NEXTCOUPON = {type = "NUMERIC", desc = "���� ������� ������"},
        BUYBACKPRICE = {type = "NUMERIC", desc = "���� ������"},
        BUYBACKDATE = {type = "NUMERIC", desc = "���� ������"},
        ISSUESIZE = {type = "NUMERIC", desc = "����� ���������"},
        PREVDATE = {type = "NUMERIC", desc = "���� ����������� ��������� ���"},
        DURATION = {type = "NUMERIC", desc = "�������"},
        LOPENPRICE = {type = "NUMERIC", desc = "����������� ���� ��������"},
        LCURRENTPRICE = {type = "NUMERIC", desc = "����������� ������� ����"},
        LCLOSEPRICE = {type = "NUMERIC", desc = "����������� ���� ��������"},
        QUOTEBASIS = {type = "STRING", desc = "��� ����"},
        PREVADMITTEDQUOT = {type = "NUMERIC", desc = "������������ ��������� ����������� ���"},
        LASTBID = {type = "NUMERIC", desc = "������ ����� �� ������ ���������� ������� ������"},
        LASTOFFER = {type = "NUMERIC", desc = "������ ����������� �� ������ ���������� ������"},
        PREVLEGALCLOSEPR = {type = "NUMERIC", desc = "���� �������� ����������� ���"},
        COUPONPERIOD = {type = "NUMERIC", desc = "������������ ������"},
        MARKETPRICE2 = {type = "NUMERIC", desc = "�������� ���� 2"},
        ADMITTEDQUOTE = {type = "NUMERIC", desc = "������������ ���������"},
        BGOP = {type = "NUMERIC", desc = "��� �� �������� ��������"},
        BGONP = {type = "NUMERIC", desc = "��� �� ���������� ��������"},
        STRIKE = {type = "NUMERIC", desc = "���� ������"},
        STEPPRICET = {type = "NUMERIC", desc = "��������� ���� ����"},
        STEPPRICE = {type = "NUMERIC", desc = "��������� ���� ���� (��� ����� ���������� FORTS)"},
        SETTLEPRICE = {type = "NUMERIC", desc = "��������� ����"},
        OPTIONTYPE = {type = "STRING", desc = "��� �������"},
        OPTIONBASE = {type = "STRING", desc = "������� �����"},
        VOLATILITY = {type = "NUMERIC", desc = "������������� �������"},
        THEORPRICE = {type = "NUMERIC", desc = "������������� ����"},
        PERCENTRATE = {type = "NUMERIC", desc = " �������������� ������"},
        ISPERCENT = {type = "STRING", desc = "��� ���� ��������"},
        CLSTATE = {type = "STRING", desc = "������ ��������"},
        CLPRICE = {type = "NUMERIC", desc = "��������� ���������� ��������"},
        STARTTIME = {type = "STRING", desc = "������ �������� ������"},
        ENDTIME = {type = "STRING", desc = "��������� �������� ������"},
        EVNSTARTTIME = {type = "STRING", desc = "������ �������� ������"},
        EVNENDTIME = {type = "STRING", desc = "��������� �������� ������"},
        MONSTARTTIME = {type = "STRING", desc = "������ �������� ������"},
        MONENDTIME = {type = "STRING", desc = "��������� �������� ������"},
        CURSTEPPRICE = {type = "STRING", desc = "������ ���� ����"},
        REALVMPRICE = {type = "NUMERIC", desc = " ������� �������� ���������"},
        MARG = {type = "STRING", desc = "�����������"},
        EXPDATE = {type = "NUMERIC", desc = "���� ���������� �����������"},
        CROSSRATE = {type = "NUMERIC", desc = "����"},
        BASEPRICE = {type = "NUMERIC", desc = "������� ����"},
        HIGHVAL = {type = "NUMERIC", desc = "������������ �������� (RTSIND)"},
        LOWVAL = {type = "NUMERIC", desc = "����������� �������� (RTSIND)"},
        ICHANGE = {type = "NUMERIC", desc = "��������� (RTSIND)"},
        IOPEN = {type = "NUMERIC", desc = "�������� �� ������ �������� (RTSIND)"},
        PCHANGE = {type = "NUMERIC", desc = "������� ��������� (RTSIND)"},
        OPENPERIODPRICE = {type = "NUMERIC", desc = "���� ������������� �������"},
        MIN_CURR_LAST = {type = "NUMERIC", desc = "����������� ������� ����"},
        SETTLECODE = {type = "STRING", desc = "��� �������� �� ���������"},
        STEPPRICECL = {type = "DOUBLE", desc = "��������� ���� ���� ��� ��������"},
        STEPPRICEPRCL = {type = "DOUBLE", desc = "��������� ���� ���� ��� ������������"},
        MIN_CURR_LAST_TI = {type = "STRING", desc = "����� ��������� ����������� ������� ����"},
        PREVLOTSIZE = {type = "DOUBLE", desc = "���������� �������� ������� ����"},
        LOTSIZECHANGEDAT = {type = "DOUBLE", desc = "���� ���������� ��������� ������� ����"},
        AUCTPRICE = {type = "NUMERIC", desc = "���� �������������� ��������"},
        CLOSING_AUCTION_VOLUME = {type = "NUMERIC", desc = "���������� � ������� �������������� ��������"},
        -------------------------------------
        LONGNAME = {type = "STRING", desc = "������ �������� �����������"},
        SHORTNAME = {type = "STRING", desc = "������� �������� �����������"},
        CODE = {type = "STRING", desc = "��� �����������"},
        CLASSNAME = {type = "STRING", desc = "�������� ������"},
        CLASS_CODE = {type = "STRING", desc = "��� ������"},
        TRADE_DATE_CODE = {type = "DOUBLE", desc = "���� ������"},
        MAT_DATE = {type = "DOUBLE", desc = "���� ���������"},
        DAYS_TO_MAT_DATE = {type = "DOUBLE", desc = "����� ���� �� ���������"},
        SEC_FACE_VALUE = {type = "DOUBLE", desc = "������� �����������"},
        SEC_FACE_UNIT = {type = "STRING", desc = "������ ��������"},
        SEC_SCALE = {type = "DOUBLE", desc = "�������� ����"},
        SEC_PRICE_STEP = {type = "DOUBLE", desc = "����������� ��� ����"},
        SECTYPE = {type = "STRING", desc = "��� �����������"},
    }
end

return roffild_win1251
