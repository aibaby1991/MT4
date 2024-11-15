﻿//+------------------------------------------------------------------+
//|                       ByPassEDay.mq4
//|                       Copyright 2024, K Lam
//|                       http://FxKillU.com
#property copyright "Copyright 2024, K Lam"
#property link      "http://FxKillU.com"
#property version   "1.00"
#include <stdlib.mqh>

//MT4 define no info
#define Version  20240924
#define MAGICMA  20240924

//MT4 define no info
#define OP_BALANCE 6
#define OP_CREDIT 7
#define OP_REBATE 8
//K LAm add
#define OP_Flowing 9//can not over 10 , the color no over 10 
#define OP_CLOSEBUY  71
#define OP_CLOSESELL 72

bool debug=false;//true;
bool LogPrint=false;//true;
bool NoTime=false;//true;

string Name_Expert="BPass";
string OWN="Copyright Feb, 2024, K Lam";
string BoS[10]={"OP_BUY","OP_SELL","OP_BUYLIMIT","OP_SELLLIMIT","OP_BUYSTOP","OP_SELLSTOP","OP_BALANCE","OP_CREDIT","OP_REBATE","OP_Flowing"};

bool NoMAGKey=true;//false;
bool NoColor=true;
color MoColor=clrGreen;
string KSymbol;
//extern int loop=2;
extern int loop=70;
extern bool SetBuy= true;//true; // Both side proccess
extern bool SetSell= true;//true; // 
extern int Pipe= 30;

struct QueueDb {
   int Ticket;
   int Type;
   string OSym;
   double OPrice;
   double Lots;
   double TP;
   double SL;
   int   MagNo;
   string  OCom;
   void Reset() {Ticket=0;Type=0;OSym="";OPrice=0;Lots=0;TP=0;SL=0;MagNo=0;OCom="";}
   };
   
QueueDb OQ[2];
//   timein,timeout
//uint Atime=GetTickCount();
uint Starttime=GetTickCount();

//+------------------------------------------------------------------+
//| Initialization
int init()
{
   KSymbol=Symbol();
   Print(AccountCompany()," ",AccountNumber(),"@",AccountServer());
   Print("leverage =", AccountLeverage()," Login User=",AccountName());
   if(NoColor) MoColor=clrNONE;
   if(!NoTime) Starttime=GetTickCount();
   return(0);
}

//+------------------------------------------------------------------+
//| expert deinitialization function
int deinit()
{
   MqlDateTime ST;
   TimeCurrent(ST);

   if(!IsTesting() && !NoTime) { //if(GetTickCount()-Atime>0)
      Print(Name_Expert," done. in ",DoubleToString(double(GetTickCount()-Starttime)/1000,3),"Seconds"); //GetTickCount()-Atime
      Print("Server Time ",TimeCurrent()," Weekday=",ST.day_of_week);
      PrintFormat("TimeLocal()= %s", string(TimeCurrent()));
      }
   printf("Server Time %4d.%02d.%02d, %02d:%02d:%02d Weekday=%1d",ST.year,ST.mon,ST.day,ST.hour,ST.min,ST.sec,ST.day_of_week);// Seconds   
//   if(false) IsMarket(KSymbol);
   
   return(0);
}
    
//+------------------------------------------------------------------+
//| Script program start function
void start() 
{
//   int cnt;
//   KSymbol=Symbol();

   //   if(NOEday=1) if(ByPassEday()) return;//
   if(ByPassEday(KSymbol)==1) {
      //CountValue(1);//can empty
      //return;
      }
   
   //Time Near to End Day   
   //MoveOut();
   
   //After End Day+
   //MoveIn();

   Print(Name_Expert," Complete Loop=",loop," used");
}

int Timer()
{
   MqlDateTime ST;
   TimeCurrent(ST);
   string TT;
   int FontSize=20;
   
   int Col1=10;
   int Row1=10;
   
   TT="Server Time ="+TimeCurrent()+" Weekday="+ST.day_of_week;
   //if(!IsTesting()) 
   SetLab("ServerTT", Col1, 24+(10*Row1), 0, TT, FontSize, "Arial", clrLime);

//   if(!IsTesting() && !NoTime) { //if(GetTickCount()-Atime>0)
//      Print(Name_Expert," done. in ",DoubleToString(double(GetTickCount()-Atime)/1000,3),"Seconds"); //GetTickCount()-Atime
//      Print("Server Time ",TimeCurrent()," Weekday=",ST.day_of_week);
      PrintFormat("TimeLocal()= %s", string(TimeCurrent()));
//      }
   printf("Server Time %4d.%02d.%02d, %02d:%02d:%02d Weekday=%1d",ST.year,ST.mon,ST.day,ST.hour,ST.min,ST.sec,ST.day_of_week);// Seconds   
   SetLab("ServerTT1", Col1, 24+(10*Row1), 0, TT, FontSize, "Arial", clrLime);   
//   if(false) IsMarket(KSymbol);
   
   return(1); 
}

int MoveIn()
{
   int Max_Spread=12;//normal 10
   int Spread=(int) MarketInfo(KSymbol,MODE_SPREAD);
   Print("MoveIn Called.");
   
   ReadList(0);//WriteQ();//write to Array
   SetTPSL(0);
   PendQueue(0);
   DelList(0);
      if(Spread>Max_Spread) 
      Print("MoveIn Called. Spread>Max_Spread RSymbol=",KSymbol," Spread=",Spread);
//      Print("MoveIn Called. Spread>Max_Spread No Trade. Wait.....");
   return(1); 
}

int MoveOut()
{
   int Max_Spread=15;//normal 10
   int Spread=(int) MarketInfo(KSymbol,MODE_SPREAD);
   Print("MoveOut Called.");
   
   ReadQ();//to Array
   WriteList(0);

   DelQueue();
   ResetTPSL();

   Print("MoveOut Called. RSymbol=",KSymbol," Spread=",Spread);
   if(Spread>Max_Spread) 
      Print("MoveOut Called. RSymbol=",KSymbol," Spread=",Spread);   
//      Print("MoveOut Called. Spread>Max_Spread No Trade.");
   
   return(1);
}

int ByPassEday(const string symbol)
{
   datetime oneMinute=60;
   datetime from, to;
   datetime serverTime = TimeCurrent();//TimeTradeServer();
   const int time = (int) MathMod(serverTime,PeriodSeconds(PERIOD_D1));
   MqlDateTime ST;
   TimeCurrent(ST);
   int session = 0;
   int week=ST.day_of_week;

   //printf("Server Time %4d.%02d.%02d, %02d:%02d:%02d Weekday=%1d",ST.year,ST.mon,ST.day,ST.hour,ST.min,ST.sec,ST.day_of_week);// Seconds   
   if(SymbolInfoSessionTrade(symbol, week, session, from, to))
      if(false) Print("Server Time=",TimeToString(time,TIME_SECONDS),
            "(week=",ST.day_of_week,
            ") from=",TimeToString(from,TIME_SECONDS),
            " to=",TimeToString(to,TIME_SECONDS),
            " Session=",session," Week=",week);

//   Print(Name_Expert," done. in ",DoubleToString(double(GetTickCount()-Starttime)/1000,3),"Seconds"); //GetTickCount()-Atime
   if(time>to-oneMinute &&time<to) {
      Print("Active MoveOut to-1=",TimeToString(to-oneMinute,TIME_SECONDS),
         " to=",TimeToString(to,TIME_SECONDS)," time=",TimeToString(time,TIME_SECONDS));
   
      MoveOut();
      return(1);
      }

   if(time>from && time<from+oneMinute) {
      Print("Active MoveIn from=",TimeToString(from,TIME_SECONDS),
         " from+1=",TimeToString(from+oneMinute,TIME_SECONDS)," time=",TimeToString(time,TIME_SECONDS));
   
      MoveIn();
      return(1);
      }
   return(0);
}


int ResetTPSL()
{
   Starttime=GetTickCount();
   int cnt;
   int cntQ;
   int Ticket;
   double OPrice;
   int OTotal=OrdersTotal();
   if(OTotal==0) return(0);
   
   for(cnt=0;cnt<OTotal;cnt++) {
      if(!(OQ[cnt].Type==OP_BUY || OQ[cnt].Type==OP_SELL)) continue;
      if(!OrderSelect(cnt, SELECT_BY_POS,MODE_TRADES)) continue;

      Ticket=OrderTicket();
      OPrice=OrderOpenPrice();
      
      if(OrderModify(Ticket,OPrice,0,0,0,clrNONE))
         Print("ResetTPSL Ticket=",Ticket," cntQ=",cntQ);
         else Print("ResetTPSL error Ticket=",Ticket," cntQ=",cntQ);

      cntQ++;
      }
//   Print(" WriteIni Ticket=",OQ[cnt].Ticket," Lots=",OQ[cnt].Lots," cnt=",cnt);
   Print("ResetTPSL Q=",cntQ,"@",DoubleToString((double(GetTickCount()-Starttime)/1000),3)," Seconds");   
   return(1); 
}

int DelQueueX()
{
   Starttime=GetTickCount();
   int cnt;
   int cntQ;
   int Ticket;
   int Type;
   
   int OTotal=OrdersTotal();
   if(OTotal==0) return(0);
   
   for(cnt=OTotal-1;cnt>=0;cnt--) {   
      if(!OrderSelect(cnt, SELECT_BY_POS,MODE_TRADES)) continue;
      
      Type=OrderType();
      if(Type==OP_BUY || Type==OP_SELL) continue;
      
      Ticket=OrderTicket();
      if(OrderDelete(Ticket))
         Print("DelQueue Ticket=",Ticket," cntQ=",cntQ);
         else Print("DelQueue error Ticket=",Ticket," cntQ=",cntQ);
      cntQ++;
      }
//   Print(" WriteIni Ticket=",OQ[cnt].Ticket," Lots=",OQ[cnt].Lots," cnt=",cnt);
   Print("DelQueue Q=",cntQ,"@",DoubleToString((double(GetTickCount()-Starttime)/1000),3)," Seconds");   
   return(1); 
}

int DelQueue()
{
   Starttime=GetTickCount();
   int cnt;
   int cntQ;
   int Ticket;
   
   int OTotal=OrdersTotal();
   if(OTotal==0) return(0);
   
   for(cnt=0;cnt<OTotal;cnt++) {
      if(OQ[cnt].Type==OP_BUY || OQ[cnt].Type==OP_SELL) continue;
      
      if(OrderDelete(OQ[cnt].Ticket))
         Print("DelQueue Ticket=",Ticket," cntQ=",cntQ);
         else Print("DelQueue error Ticket=",Ticket," cntQ=",cntQ);
      cntQ++;
      }
//   Print(" WriteIni Ticket=",OQ[cnt].Ticket," Lots=",OQ[cnt].Lots," cnt=",cnt);
   Print("DelQueue Q=",cntQ,"@",DoubleToString((double(GetTickCount()-Starttime)/1000),3)," Seconds");   
   return(1); 
}

int ReadQ()
{
   //datetime 
   Starttime=GetTickCount();
   int cnt;
   int OTotal=OrdersTotal();
   if(OTotal==0) return(0);
   ArrayResize(OQ,OTotal);

   for(cnt=0;cnt<OTotal;cnt++) {
      if(!OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES)) continue;
      //if(OrderSymbol()!=RSymbol) continue;
      //if(anyMag==0) if(OrderMagicNumber()!=MAGICMA) continue; 
      OQ[cnt].Reset();

      OQ[cnt].Ticket=OrderTicket();
      OQ[cnt].Type=OrderType();
      OQ[cnt].OSym=OrderSymbol();   
      OQ[cnt].OPrice=OrderOpenPrice();
      OQ[cnt].Lots=OrderLots();;
      OQ[cnt].TP=OrderTakeProfit();
      OQ[cnt].SL=OrderStopLoss();
      OQ[cnt].MagNo=OrderMagicNumber();
      OQ[cnt].OCom=OrderComment();
      Print("ByPass readQ order #", OQ[cnt].Ticket, " is ", OQ[cnt].OSym," cnt=",cnt);
      }//for(cnt=0;cnt<OTotal;cnt++) {
   Print("ReadQ @",DoubleToString((double(GetTickCount()-Starttime)/1000),3)," Seconds");
   return(1);
}

//+------------------------------------------------------------------
//| common Lib
//| Delete Ini file
int DelList(int notuse)
{
   Starttime=GetTickCount();
   int err;
   string FileName = StringConcatenate(Name_Expert,"List.ini");
//   int FileHandle=FileOpen(FileName,FILE_CSV|FILE_READ, ",");

   if(FileIsExist(FileName)) //delete

   if(FileDelete(FileName)) {   
         if(LogPrint) Print(FileName," File Delete!");
         } else {
         if(LogPrint) Print("Error code ",err," Failed to Delete file ",FileName);
         }

   Print("DelIni @",DoubleToString((double(GetTickCount()-Starttime)/1000),3)," Seconds");
   return(1);
}

//+------------------------------------------------------------------
//| read Ini file
int ReadList(int notuse)
{
   Starttime=GetTickCount();
   int cnt;
   int err;
   int tmpV;
   int tmpVV;
   string Name;
   string ValueS;
   double Value;

   int OTotal=OrdersTotal();
   if(OTotal==0) return(0);
   ArrayResize(OQ,OTotal,10);
   
   string FileName = StringConcatenate(Name_Expert,"List.ini");
   int FileHandle=FileOpen(FileName,FILE_CSV|FILE_READ, ",");
   
   if(FileHandle<0) {
      err = GetLastError();
      if(err==5004) {
         if(LogPrint) Print(FileName," File NOT Found, will Build after Close EA!");
         } else {
         if(LogPrint) Print("Error code ",err," Failed to open file ",FileName, " to READ."); 
         }
      }
      
   for(cnt=0;cnt<OTotal;cnt++) {
      //if(!OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES)) continue;
      //if(OrderSymbol()!=RSymbol) continue;
      //if(anyMag==0) if(OrderMagicNumber()!=MAGICMA) continue; 
      if(FileIsEnding(FileHandle)) break;//no need seek FileSeek(FileHandle,cnt,SEEK_SET);
      OQ[cnt].Reset();
            
      Name=FileReadString(FileHandle);
      Value=FileReadNumber(FileHandle);
      tmpV=StringToInteger(Name);
      if(tmpV==Value)
      OQ[cnt].Ticket=tmpV;
      
      Name=FileReadString(FileHandle);
      Value=FileReadNumber(FileHandle);
      tmpVV=StringToInteger(Name);
      if(tmpV==tmpVV) OQ[cnt].Type=Value;
      
      Name=FileReadString(FileHandle);
      ValueS=FileReadString(FileHandle);
      tmpVV=StringToInteger(Name);
      if(tmpV==tmpVV) OQ[cnt].OSym=ValueS;

      Name=FileReadString(FileHandle);
      Value=FileReadNumber(FileHandle);
      tmpVV=StringToInteger(Name);
      if(tmpV==tmpVV) OQ[cnt].OPrice=Value;

      Name=FileReadString(FileHandle);
      Value=FileReadNumber(FileHandle);
      tmpVV=StringToInteger(Name);
      if(tmpV==tmpVV) OQ[cnt].Lots=Value;

      Name=FileReadString(FileHandle);
      Value=FileReadNumber(FileHandle);
      tmpVV=StringToInteger(Name);
      if(tmpV==tmpVV) OQ[cnt].TP=Value;
            
      Name=FileReadString(FileHandle);
      Value=FileReadNumber(FileHandle);
      tmpVV=StringToInteger(Name);
      if(tmpV==tmpVV) OQ[cnt].SL=Value;
      
      Name=FileReadString(FileHandle);
      Value=FileReadNumber(FileHandle);
      tmpVV=StringToInteger(Name);
      if(tmpV==tmpVV) OQ[cnt].MagNo=Value;
      
      Name=FileReadString(FileHandle);
      ValueS=FileReadString(FileHandle);
      tmpVV=StringToInteger(Name);
      if(tmpV==tmpVV) OQ[cnt].OCom=ValueS;
      
      Print("ByPass ReadIni order OQ #", OQ[cnt].Ticket, " is ", OQ[cnt].OSym);
      }//for(cnt=0;cnt<OTotal;cnt++) {
   FileClose(FileHandle);
   Print("ReadIni @",DoubleToString((double(GetTickCount()-Starttime)/1000),3)," Seconds");
   return(1);
}

int SetTPSL(int notuse)
{
   Starttime=GetTickCount();
   int cnt;
   int cntQ;
   int QTotal=ArraySize(OQ);
   if(QTotal==0) return(0);
   
   for(cnt=0;cnt<QTotal;cnt++) {
      if(!(OQ[cnt].Type==OP_BUY || OQ[cnt].Type==OP_SELL)) continue;
      if(!OrderSelect(OQ[cnt].Ticket, SELECT_BY_TICKET,MODE_TRADES)) continue;
      if(OrderModify(OQ[cnt].Ticket,OQ[cnt].OPrice,OQ[cnt].SL,OQ[cnt].TP,0,clrNONE))
         Print(" SetTPSL Ticket=",OQ[cnt].Ticket," Lots=",OQ[cnt].Lots,         
            " SL=",OQ[cnt].SL," TP=",OQ[cnt].TP," cnt=",cnt);
         else Print(" SetTPSL error Ticket=",OQ[cnt].Ticket," Lots=",OQ[cnt].Lots,         
            " SL=",OQ[cnt].SL," TP=",OQ[cnt].TP," cnt=",cnt);
      cntQ++;
      }
//   Print(" WriteIni Ticket=",OQ[cnt].Ticket," Lots=",OQ[cnt].Lots," cnt=",cnt);
   Print("SetTPSL Q=",cntQ,"@",DoubleToString((double(GetTickCount()-Starttime)/1000),3)," Seconds");   
   return(1); 
}

int PendQueue(int notuse)
{   
   Starttime=GetTickCount();
   int cnt;
   int cntQ;
   int MakeTicket;
   int slippage=0;
   int QTotal=ArraySize(OQ);
   if(QTotal==0) return(0);
   
   for(cnt=0;cnt<QTotal;cnt++) {//if(!(OQ[cnt].Type==OP_BUY || OQ[cnt].Type==OP_SELL)) continue;
      if(!(OQ[cnt].Type==OP_BUYSTOP || OQ[cnt].Type==OP_SELLSTOP
         || OQ[cnt].Type==OP_BUYLIMIT || OQ[cnt].Type==OP_SELLLIMIT)) continue;
      if(OrderSelect(OQ[cnt].Ticket, SELECT_BY_TICKET,MODE_TRADES)) continue;

      MakeTicket=OrderSend(OQ[cnt].OSym,OQ[cnt].Type,OQ[cnt].Lots,OQ[cnt].OPrice,
         slippage,OQ[cnt].SL,OQ[cnt].TP,OQ[cnt].OCom,OQ[cnt].MagNo,0,clrNONE);

      Print(" PendQueue Ticket=",MakeTicket," Lots=",OQ[cnt].Lots,         
            " SL=",OQ[cnt].SL," TP=",OQ[cnt].TP," cntQ=",cntQ);
      cntQ++;
      }
//   Print(" WriteIni Ticket=",OQ[cnt].Ticket," Lots=",OQ[cnt].Lots," cnt=",cnt);
   Print("PendQueue Q=",cntQ,"@",DoubleToString((double(GetTickCount()-Starttime)/1000),3)," Seconds");   

   return(1);
}
   
//+------------------------------------------------------------------
//| WriteList file
int WriteList(int notuse)
{
   //datetime 
   Starttime=GetTickCount();
   int cnt;
   int QTotal=ArraySize(OQ);
   if(QTotal==0) return(0);
   
   string FileName = StringConcatenate(Name_Expert,"List.ini");
   int FileHandle=FileOpen(FileName,FILE_CSV|FILE_WRITE, ',');
   if(FileHandle<0) { 
      Print("Failed to open WRITE file by the absolute path ",FileName); 
      Print("Error code ",GetLastError()); 
      }

   if(FileHandle>0) {
      for(cnt=0;cnt<QTotal;cnt++) {//if(FileIsEnding(FileHandle)) break;
         FileWrite(FileHandle,OQ[cnt].Ticket,OQ[cnt].Ticket);
         FileWrite(FileHandle,OQ[cnt].Ticket,OQ[cnt].Type);
         FileWrite(FileHandle,OQ[cnt].Ticket,OQ[cnt].OSym);
         FileWrite(FileHandle,OQ[cnt].Ticket,OQ[cnt].OPrice);
         FileWrite(FileHandle,OQ[cnt].Ticket,OQ[cnt].Lots);
         FileWrite(FileHandle,OQ[cnt].Ticket,OQ[cnt].TP);
         FileWrite(FileHandle,OQ[cnt].Ticket,OQ[cnt].SL);
         FileWrite(FileHandle,OQ[cnt].Ticket,OQ[cnt].MagNo);
         FileWrite(FileHandle,OQ[cnt].Ticket,OQ[cnt].OCom);
         //if(debug) 
         Print(" WriteIni Ticket=",OQ[cnt].Ticket," Lots=",OQ[cnt].Lots," cnt=",cnt);
         }
      FileClose(FileHandle);
      }
return(0);
}




bool IsMarketOpen(const string symbol) 
{
  datetime oneMinute=60;
  datetime from, to;
  datetime serverTime = TimeCurrent();//  TimeTradeServer();
  
  MqlDateTime dt;
  TimeToStruct(serverTime,dt);
  const ENUM_DAY_OF_WEEK day_of_week = (ENUM_DAY_OF_WEEK) dt.day_of_week;
  const int time = (int) MathMod(serverTime,PeriodSeconds(PERIOD_D1));
  int session = 0;
  while(SymbolInfoSessionTrade (symbol, day_of_week, session, from, to)) {
    if(time >=from+oneMinute && time <= to-oneMinute) {
    
      return true;
    }
    session++;
  }
  return false;
}

bool IsMarket(const string symbol)
{
   datetime oneMinute=60;
   datetime from, to;
   datetime serverTime = TimeCurrent();//  TimeTradeServer();
   MqlDateTime ST;
   TimeCurrent(ST);
   
   MqlDateTime dt;
   TimeToStruct(serverTime,dt);
   const ENUM_DAY_OF_WEEK day_of_week = (ENUM_DAY_OF_WEEK) dt.day_of_week;
   const int time = (int) MathMod(serverTime,PeriodSeconds(PERIOD_D1));
   int session = 0;
//  Print("Server Time ",TimeCurrent()," Weekday=",ST.day_of_week);
   int week;

      //while(SymbolInfoSessionTrade(KSymbol, week, session, from, to)) {
   for(session=0;session<3;session++) {
      for(week=0;week<7;week++) {
         if(SymbolInfoSessionTrade(KSymbol, week, session, from, to))
            Print("found@Session=",session," Week=",week," ********************************");

         Print("from=",TimeToString(from,TIME_SECONDS),
            " to=",TimeToString(to,TIME_SECONDS),
            " time=",TimeToString(time,TIME_SECONDS),
            " Session=",session," Week=",week);
            
   if(time<to && time>to-oneMinute)
      MoveOut();
   if(time>from && time<from+oneMinute)
      MoveIn();

      if(time >=from+oneMinute && time <= to-oneMinute) {
         //Print("Server Time ",TimeCurrent()," Weekday=",ST.day_of_week);
         //return true;
         }
//       session++;
       }
      }
  return false;
}

//+------------------------------------------------------------------+
//|
int Caltime(int in, string textin) //Not busy
{
   if(NoTime || IsTesting()) return(0);

   if(in==1) {
      Starttime=GetTickCount();
      return(1);
      }
   if(in==0) {
      if(GetTickCount()-Starttime>0)
         Print(textin," in ",DoubleToString((double(GetTickCount()-Starttime)/1000),3),"Seconds");
      return(1);
      }

   return(0);
}

//+------------------------------------------------------------------+
//
void SetLab(string Display_name,int x,int y,int corner,string text,int fontsize,string fontname,color colorshow=-1)
{
   ObjectCreate(Display_name,OBJ_LABEL,0,0,0);
   ObjectSet(Display_name,OBJPROP_XDISTANCE,x);
   ObjectSet(Display_name,OBJPROP_YDISTANCE,y);
   ObjectSet(Display_name,OBJPROP_CORNER,corner);
   ObjectSetText(Display_name,text,fontsize,fontname,colorshow);
}

//+------------------------------------------------------------------+
//
bool Same(double number1,double number2)
{
   if(NormalizeDouble(number1-number2,8)==0) return(true);
      else return(false);
}

//+------------------------------------------------------------------+
//
bool ALargeB(double number1,double number2)
{
   if(NormalizeDouble(number1-number2,8)>0) return(true);
      else return(false);
}
//-----------------------End
