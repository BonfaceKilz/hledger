
module Tests
where

import Text.ParserCombinators.Parsec
import Test.QuickCheck
import Test.HUnit
-- trying to make "*Tests> test" work
-- hiding (test)
--import qualified Test.HUnit (Test.HUnit.test)

import Options
import Models
import Account
import Parse

-- sample data

transaction1_str  = "  expenses:food:dining  $10.00\n"

transaction1 = Transaction "expenses:food:dining" (Amount "$" 10)

entry1_str = "\
\2007/01/28 coopportunity\n\
\  expenses:food:groceries                 $47.18\n\
\  assets:checking\n\
\\n" --"

entry1 =
    (Entry "2007/01/28" False "" "coopportunity" 
               [Transaction "expenses:food:groceries" (Amount "$" 47.18), 
                Transaction "assets:checking" (Amount "$" (-47.18))])

entry2_str = "\
\2007/01/27 * joes diner\n\
\  expenses:food:dining                    $10.00\n\
\  expenses:gifts                          $10.00\n\
\  assets:checking                        $-20.00\n\
\\n" --"

entry3_str = "\
\2007/01/01 * opening balance\n\
\    assets:cash                                $4.82\n\
\    equity:opening balances\n\
\\n\
\2007/01/01 * opening balance\n\
\    assets:cash                                $4.82\n\
\    equity:opening balances\n\
\\n\
\2007/01/28 coopportunity\n\
\  expenses:food:groceries                 $47.18\n\
\  assets:checking\n\
\\n" --"

periodic_entry1_str = "\
\~ monthly from 2007/2/2\n\
\  assets:saving            $200.00\n\
\  assets:checking\n\
\\n" --"

periodic_entry2_str = "\
\~ monthly from 2007/2/2\n\
\  assets:saving            $200.00         ;auto savings\n\
\  assets:checking\n\
\\n" --"

periodic_entry3_str = "\
\~ monthly from 2007/01/01\n\
\    assets:cash                                $4.82\n\
\    equity:opening balances\n\
\\n\
\~ monthly from 2007/01/01\n\
\    assets:cash                                $4.82\n\
\    equity:opening balances\n\
\\n" --"

ledger1_str = "\
\\n\
\2007/01/27 * joes diner\n\
\  expenses:food:dining                    $10.00\n\
\  expenses:gifts                          $10.00\n\
\  assets:checking                        $-20.00\n\
\\n\
\\n\
\2007/01/28 coopportunity\n\
\  expenses:food:groceries                 $47.18\n\
\  assets:checking                        $-47.18\n\
\\n\
\" --"

ledger2_str = "\
\;comment\n\
\2007/01/27 * joes diner\n\
\  expenses:food:dining                    $10.00\n\
\  assets:checking                        $-47.18\n\
\\n" --"

ledger3_str = "\
\2007/01/27 * joes diner\n\
\  expenses:food:dining                    $10.00\n\
\;intra-entry comment\n\
\  assets:checking                        $-47.18\n\
\\n" --"

ledger4_str = "\
\!include \"somefile\"\n\
\2007/01/27 * joes diner\n\
\  expenses:food:dining                    $10.00\n\
\  assets:checking                        $-47.18\n\
\\n" --"

ledger5_str = ""

ledger6_str = "\
\~ monthly from 2007/1/21\n\
\    expenses:entertainment  $16.23        ;netflix\n\
\    assets:checking\n\
\\n\
\; 2007/01/01 * opening balance\n\
\;     assets:saving                            $200.04\n\
\;     equity:opening balances                         \n\
\\n" --"

ledger7_str = "\
\2007/01/01 * opening balance\n\
\    assets:cash                                $4.82\n\
\    equity:opening balances                         \n\
\\n\
\2007/01/02 * ayres suites\n\
\    expenses:vacation                        $179.92\n\
\    assets:checking                                 \n\
\\n\
\2007/01/02 * auto transfer to savings\n\
\    assets:saving                            $200.00\n\
\    assets:checking                                 \n\
\\n\
\2007/01/03 * poquito mas\n\
\    expenses:food:dining                       $4.82\n\
\    assets:cash                                     \n\
\\n\
\2007/01/03 * verizon\n\
\    expenses:phone                            $95.11\n\
\    assets:checking                                 \n\
\\n\
\2007/01/03 * discover\n\
\    liabilities:credit cards:discover         $80.00\n\
\    assets:checking                                 \n\
\\n\
\2007/01/04 * blue cross\n\
\    expenses:health:insurance                 $90.00\n\
\    assets:checking                                 \n\
\\n\
\2007/01/05 * village market liquor\n\
\    expenses:food:dining                       $6.48\n\
\    assets:checking                                 \n\
\\n" --"

ledger7 = Ledger
          [] 
          [] 
          [
           Entry {
                  edate="2007/01/01", estatus=False, ecode="*", edescription="opening balance",
                  etransactions=[
                                Transaction {taccount="assets:cash", 
                                             tamount=Amount {currency="$", quantity=4.82}},
                                Transaction {taccount="equity:opening balances", 
                                             tamount=Amount {currency="$", quantity=(-4.82)}}
                               ]
                 },
           Entry {
                  edate="2007/02/01", estatus=False, ecode="*", edescription="ayres suites",
                  etransactions=[
                                Transaction {taccount="expenses:vacation", 
                                             tamount=Amount {currency="$", quantity=179.92}},
                                Transaction {taccount="assets:checking", 
                                             tamount=Amount {currency="$", quantity=(-179.92)}}
                               ]
                 }
          ]

-- utils

assertEqual' e a = assertEqual "" e a

parse' p ts = parse p "" ts

assertParseEqual :: (Show a, Eq a) => a -> (Either ParseError a) -> Assertion
assertParseEqual expected parsed =
    case parsed of
      Left e -> parseError e
      Right v -> assertEqual " " expected v

parseEquals :: Eq a => (Either ParseError a) -> a -> Bool
parseEquals parsed other =
    case parsed of
      Left e -> False
      Right v -> v == other

-- hunit tests

tests = let t l f = TestLabel l $ TestCase f in TestList
        [
          t "test_ledgertransaction" test_ledgertransaction
        , t "test_ledgerentry" test_ledgerentry
        , t "test_autofillEntry" test_autofillEntry
        , t "test_expandAccountNames" test_expandAccountNames
        , t "test_ledgerAccountNames" test_ledgerAccountNames
        ]

tests2 = Test.HUnit.test 
         [
          "test1" ~: assertEqual "2 equals 2" 2 2
         ]

test_ledgertransaction :: Assertion
test_ledgertransaction =
    assertParseEqual transaction1 (parse' ledgertransaction transaction1_str)      

test_ledgerentry =
    assertParseEqual entry1 (parse' ledgerentry entry1_str)

test_autofillEntry = 
    assertEqual'
    (Amount "$" (-47.18))
    (tamount $ last $ etransactions $ autofillEntry entry1)

test_expandAccountNames =
    assertEqual'
    ["assets","assets:cash","assets:checking","expenses","expenses:vacation"]
    (expandAccountNames ["assets:cash","assets:checking","expenses:vacation"])

test_ledgerAccountNames =
    assertEqual'
    ["assets","assets:cash","assets:checking","equity","equity:opening balances","expenses","expenses:vacation"]
    (ledgerAccountNames ledger7)

-- quickcheck properties

props =
    [
     parse' ledgertransaction transaction1_str `parseEquals`
     (Transaction "expenses:food:dining" (Amount "$" 10))
    ,
     ledgerAccountNames ledger7 == 
     ["assets","assets:cash","assets:checking","equity","equity:opening balances","expenses","expenses:vacation"]
    ,
     ledgerPatternArgs [] == ([],[])
    ,ledgerPatternArgs ["a"] == (["a"],[])
    ,ledgerPatternArgs ["a","b"] == (["a","b"],[])
    ,ledgerPatternArgs ["a","b","--"] == (["a","b"],[])
    ,ledgerPatternArgs ["a","b","--","c","b"] == (["a","b"],["c","b"])
    ,ledgerPatternArgs ["--","c"] == ([],["c"])
    ,ledgerPatternArgs ["--"] == ([],[])
    ]

