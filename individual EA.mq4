//+------------------------------------------------------------------+
//|                     FINANCIAL COMPUTING INDIVIDUAL PROJECCT .mq4 |
//|                                                        Jerry Guo |
//|                                           https://www.uic.edu.hk |
//+------------------------------------------------------------------+
#property copyright "Jerry Guo"
#property link      "https://www.uic.edu.hk"
#property version   "1.00"
#property strict

     
      extern int LotsPersent= 10;
      extern int MaxProfit= 100;     // means the +10%
      extern int MaxLoss= 15;    // means the -10%
      extern int Slippage = 3;
      extern int MagicNumber = 888888;
      
      extern int MA1 = 13;    // Fibonacci Moving Average
      extern int MA2 = 34;
      extern int MA3 = 55;
      extern bool bollinger=true;        // bollinger bands filter
      extern int bbtimeframe=0;
      extern int bbperiod=20;
      extern double deviation=2.0;
      extern double bbdistance=13;
      extern int bbmethod=0;
      extern int bbprice=1;
      extern int bbshift=0;
      extern int closeshift=0;
      
      int Ticket;
      int OrderTime;
      bool OrderOpen=false;
      double Equity = 0;
      
      double HistoryBuyProfit;
      double HistorySellProfit;
      double NewHistoryBuyProfit;
      double NewHistorySellProfit;
      
      int init()
        {
         return(0);
        }
      
      int deinit()
        {
         return(0);
        }
      
      
      int start()
        {
            //using the exist function to get the MA value
            double MA10=iMA(NULL,0,MA1,0,MODE_EMA,PRICE_CLOSE,0);
            double MA11=iMA(NULL,0,MA1,0,MODE_EMA,PRICE_CLOSE,1);
            double MA20=iMA(NULL,0,MA2,0,MODE_EMA,PRICE_CLOSE,0);
            double MA21=iMA(NULL,0,MA2,0,MODE_EMA,PRICE_CLOSE,1);
            double MA30=iMA(NULL,0,MA3,0,MODE_EMA,PRICE_CLOSE,0);
            double MA31=iMA(NULL,0,MA3,0,MODE_EMA,PRICE_CLOSE,1);
            double ma=iMA(NULL,0,13,0,MODE_EMA,PRICE_CLOSE,0);
            double stddev,bbup,bbdn;//for bollinger band indicators
            
            
            if (Time[0] != OrderTime && Time[1] != OrderTime) OrderOpen = false;
            
            double Lots =NormalizeDouble(AccountFreeMargin() / 1000.0 * (LotsPersent/ 100.0),1);//AccountFreeMargin() AccountBalance()
           
      	   stddev=iStdDev(Symbol(),bbtimeframe,bbperiod,0,bbmethod,bbprice,bbshift);  //return value of  
            bbup=ma+(deviation*stddev); // upperbound of BB
            bbdn=ma-(deviation*stddev); // lowerbound of BB
            
        
            int HoldingOrders = 0;
            
            if( OrdersTotal() != 0) {
               for (int i = 0; i < OrdersTotal(); i++) {
                  if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){};
                  if (OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber){
                      HoldingOrders++;
                  }
               }
            }
             
            if(HoldingOrders==0)
            
            Equity=AccountEquity();
            
            if(MA11<MA21 && MA10>=MA20 && MA10>MA30 && OrderOpen==false)
            {
               if(Close[closeshift]>bbup)
               {
                if(NewLotsCount(OP_SELL)>0)
                {
                   NewHistorySellProfit+=NewHoldingSellProfit(); 
                   NewCloseAllSell();
                }
                if(LotsCount(OP_SELL)>0 && NewLotsCount(OP_BUY)==0){
                   Ticket=OrderSend(Symbol(),OP_BUY,LotsCount(OP_SELL),NormalizeDouble(Ask, Digits),Slippage,0,0,"newdummy-buy",MagicNumber+1,0,Yellow);
                }
                
                Ticket=OrderSend(Symbol(),OP_BUY,Lots,NormalizeDouble(Ask, Digits),Slippage,0,0,"dummy-buy",MagicNumber,0,Red);
                if(Ticket>0){
                       if (OrderSelect(Ticket,SELECT_BY_TICKET,MODE_TRADES)){
                          OrderOpen=true;
                          OrderTime=Time[0];
                          Print("Pivot dummy-buy order opened : ",OrderOpenPrice());
                       }
                    else{
                       Print("Error opening Pivot dummy-buy order : ",GetLastError());
                       return(0);
                    }
                 }
               }
             
            }
        else
        if(MA11>MA21 && MA10<=MA20 && MA10<MA30 && OrderOpen==false){
           if(Close[closeshift]<bbdn){
             
             if(NewLotsCount(OP_BUY)>0)
             {
                NewHistoryBuyProfit+=NewHoldingBuyProfit(); 
                NewCloseAllBuy();
             }
             if(LotsCount(OP_BUY)>0 && NewLotsCount(OP_SELL)==0){
                Ticket=OrderSend(Symbol(),OP_SELL,LotsCount(OP_BUY),NormalizeDouble(Bid, Digits),Slippage,0,0,"newdummy-sell",MagicNumber+1,0,Green);
             }
             
             Ticket=OrderSend(Symbol(),OP_SELL,Lots,NormalizeDouble(Bid, Digits),Slippage,0,0,"dummy-sell",MagicNumber,0,Blue);
             if(Ticket>0){
                    if (OrderSelect(Ticket,SELECT_BY_TICKET,MODE_TRADES)){
                       OrderOpen=true;
                       OrderTime=Time[0];
                       Print("Pivot dummy-sell order opened : ",OrderOpenPrice());
                    }
                    else{
                       Print("Error opening Pivot dummy-sell order : ",GetLastError());
                       return(0);
                    }
              }
        
         }   
      }
         
         
              
          
             
              
              
              if(MA11<MA21 && MA10>=MA20)//sell when cross appear
              CloseAllWinSell();
              
              if(MA11>MA21 && MA10<=MA20)
              CloseAllWinBuy();
              
              if(iMA(NULL,0,3,0,MODE_EMA,PRICE_CLOSE,0)<MA11 && iMA(NULL,0,3,0,MODE_EMA,PRICE_CLOSE,0)>MA10)//MA3<MA13(PAST)
              CloseAllWinSell();
              
              if(iMA(NULL,0,3,0,MODE_EMA,PRICE_CLOSE,0)>MA11 && iMA(NULL,0,3,0,MODE_EMA,PRICE_CLOSE,0)<MA10)
              CloseAllWinBuy();
              
             if(HoldingBuyProfit()+HistoryBuyProfit+NewHoldingSellProfit()+NewHistorySellProfit > AccountEquity()*MaxProfit/100/2){
                 CloseAllBuy(); NewCloseAllSell(); NewHistorySellProfit=0; HistoryBuyProfit=0;
             }
             if(HoldingSellProfit()+HistorySellProfit+NewHoldingBuyProfit()+NewHistoryBuyProfit > AccountEquity()*MaxProfit/100/2){
                 CloseAllSell(); NewCloseAllBuy(); NewHistoryBuyProfit=0; HistorySellProfit=0;
             }
             
             
             if(AccountEquity()-Equity>=AccountEquity()*MaxProfit/100){ CloseAllSell();CloseAllBuy(); NewCloseAllSell();NewCloseAllBuy();NewHistorySellProfit=0; HistoryBuyProfit=0; NewHistoryBuyProfit=0; HistorySellProfit=0;}//stop when 100% 
     
             if(Equity-AccountEquity()>=AccountEquity()*MaxLoss/100){CloseAllSell();CloseAllBuy();}//stop loss at 15%
      
      
         return(0);
        }
      //+------------------------------------------------------------------+
      
      
      void CloseAllSell()
      {
         bool CAS = FALSE;
         for (int t=0; t<OrdersTotal(); t++)
         {
            OrderSelect(t, SELECT_BY_POS, MODE_TRADES);
            if (OrderType() == OP_SELL && OrderMagicNumber() == MagicNumber )
            CAS = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(OrderClosePrice(), Digits), Slippage, Yellow);
         }
      }
      
      
      void CloseAllBuy() 
      {
         bool CAB = FALSE;
         for (int t=0; t<OrdersTotal(); t++) 
         {
            OrderSelect(t, SELECT_BY_POS, MODE_TRADES);
            if (OrderType() == OP_BUY && OrderMagicNumber() == MagicNumber)
            CAB = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(OrderClosePrice(), Digits), Slippage, Yellow);
         }
      }
      
      
      void CloseAllWinSell() 
      {
         bool CAWS = FALSE;
         for (int t=0; t<OrdersTotal(); t++) 
         {
            OrderSelect(t, SELECT_BY_POS, MODE_TRADES);
            if (OrderType() == OP_SELL && OrderMagicNumber() == MagicNumber && OrderProfit() > 0.0 ){
               HistorySellProfit+=OrderProfit();
               CAWS = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(OrderClosePrice(), Digits), Slippage, Yellow);
            }
         }
      }
      
      void CloseAllWinBuy() 
      {
         bool CAWB = FALSE;
         for (int t=0; t<OrdersTotal(); t++)
         {
            OrderSelect(t, SELECT_BY_POS, MODE_TRADES);
            if (OrderType() == OP_BUY && OrderMagicNumber() == MagicNumber && OrderProfit() > 0.0){
               HistoryBuyProfit+=OrderProfit();
               CAWB = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(OrderClosePrice(), Digits), Slippage, Yellow);
            }
         }
      }
      
      
      
      double HoldingBuyProfit()
      {
         double BuyProfit = 0;
         for (int t=0; t<OrdersTotal(); t++)
         {
            OrderSelect(t, SELECT_BY_POS, MODE_TRADES);
            if (OrderType() == OP_BUY && OrderMagicNumber() == MagicNumber)
            BuyProfit += OrderProfit();
         }
         return (BuyProfit);
      }
      
      
      double HoldingSellProfit()
      {
         double SellProfit = 0;
         for (int t=0; t<OrdersTotal(); t++)
         {
            OrderSelect(t, SELECT_BY_POS, MODE_TRADES);
            if (OrderType() == OP_SELL && OrderMagicNumber() == MagicNumber)
            SellProfit += OrderProfit();
         }
         return (SellProfit);
      }
      
      
      double NewHoldingBuyProfit()
      {
         double NewBuyProfit = 0;
         for (int t=0; t<OrdersTotal(); t++)
         {
            OrderSelect(t, SELECT_BY_POS, MODE_TRADES);
            if (OrderType() == OP_BUY && OrderMagicNumber() == MagicNumber+1)
            NewBuyProfit += OrderProfit();
         }
         return (NewBuyProfit);
      }
      
      
      double NewHoldingSellProfit()
      {
         double NewSellProfit = 0;
         for (int t=0; t<OrdersTotal(); t++)
         {
            OrderSelect(t, SELECT_BY_POS, MODE_TRADES);
            if (OrderType() == OP_SELL && OrderMagicNumber() == MagicNumber+1)
            NewSellProfit += OrderProfit();
         }
         return (NewSellProfit);
      }
      
      
      double LotsCount(int type) 
      {
         double BuyLots=0;
         double SellLots=0;
         for (int t=0; t<OrdersTotal(); t++) 
         {
            OrderSelect(t, SELECT_BY_POS, MODE_TRADES);
            if (OrderType() == OP_BUY && OrderMagicNumber() == MagicNumber )BuyLots+=OrderLots();
            if (OrderType() == OP_SELL && OrderMagicNumber() == MagicNumber )SellLots+=OrderLots();
         }
         switch(type)
         {
            case OP_BUY: return (BuyLots);
            break;
            case OP_SELL: return (SellLots);
            break;
         }
         return(0);
      }
      
      double NewLotsCount(int type) 
      {
         double BuyLots=0;
         double SellLots=0;
         for (int t=0; t<OrdersTotal(); t++) 
         {
            OrderSelect(t, SELECT_BY_POS, MODE_TRADES);
            if (OrderType() == OP_BUY && OrderMagicNumber() == MagicNumber+1 )BuyLots+=OrderLots();
            if (OrderType() == OP_SELL && OrderMagicNumber() == MagicNumber+1 )SellLots+=OrderLots();
         }
         switch(type)
         {
            case OP_BUY: return (BuyLots);
            break;
            case OP_SELL: return (SellLots);
            break;
         }
         return(0);
      }
      
      
      void NewCloseAllSell()
      {
         bool CAS = FALSE;
         for (int t=0; t<OrdersTotal(); t++)
         {
            OrderSelect(t, SELECT_BY_POS, MODE_TRADES);
            if (OrderType() == OP_SELL && OrderMagicNumber() == MagicNumber+1 )
            CAS = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(OrderClosePrice(), Digits), Slippage, Yellow);
         }
      }
      
      
      void NewCloseAllBuy() 
      {
         bool CAB = FALSE;
         for (int t=0; t<OrdersTotal(); t++) 
         {
            OrderSelect(t, SELECT_BY_POS, MODE_TRADES);
            if (OrderType() == OP_BUY && OrderMagicNumber() == MagicNumber+1)
            CAB = OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(OrderClosePrice(), Digits), Slippage, Yellow);
         }
      }