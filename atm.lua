accounts = {
     balance = {},
     pin = {},
     credit = {}
}

minetest.register_on_newplayer(function(player)
     accounts.balance[player:get_player_name()] = 0
     accounts.pin[player:get_player_name()] = 0000
     accounts.credit[player:get_player_name()] = 0
     save_account()
end)

minetest.register_on_joinplayer(function(player)
     for k, v in pairs(accounts.balance) do
          if not accounts.balance[player:get_player_name()] then
               accounts.balance[player:get_player_name()] = 0
               accounts.pin[player:get_player_name()] = 0000
               accounts.credit[player:get_player_name()] = 0
               save_account()
          else
               return false
          end
     end
end)

minetest.register_chatcommand("set_pin", {
     param = "<number>",
     description = "Set pin for bank account.",
     func = function(name, param)
          if param == nil or param == "" then
               minetest.chat_send_player(name, "[Account] No numbers entered.")
          elseif string.match(param, "%d%d%d%d") ~= param then
               minetest.chat_send_player(name, "[Account] Invalid number entered.")
          elseif string.match(param, "%d%d%d%d") then
               minetest.chat_send_player(name, "[Account] Pin successfully set!")
               accounts.pin[name] = param
               local player = minetest.get_player_by_name(name)
               local inv = player:get_inventory()
               inv:add_item("main", {name="bank_accounts:atm_card", count=1})
               save_account()
          end
     end
})

minetest.register_craftitem("bank_accounts:atm_card", {
     description = "ATM Card",
     inventory_image = "atm_card.png",
     groups = {not_in_creative_inventory=1},
          stack_max = 1,
})

minetest.register_node("bank_accounts:atm", {
     description = "Automatic Teller Machine",
     drawtype = "mesh",
     mesh = "atm.obj",
     paramtype = "light",
     paramtype2 = "facedir",
     groups = {cracky=3, crumbly=3, oddly_breakable_by_hand=2},
     on_rightclick = function(pos, node, player, itemstack, pointed_thing)
          if player:get_wielded_item():to_string() ~= "bank_accounts:atm_card" then
               minetest.chat_send_player(player:get_player_name(), "[ATM] Must use ATM card.")
          else
               minetest.show_formspec(player:get_player_name(), "bank_accounts:atm_home",
                    "size[8,8]" ..
                    "pwdfield[2,4;4,1;fourdigitpin;Four Digit Pin:]" ..
                    "button[5,6;2,1;enter;Enter]" ..
                    "button_exit[3,6;2,1;exit;Cancel]")
          end
     end
})

local balance = {}
function get_balance(player)
     for k, v in pairs(accounts.balance) do
          if accounts.balance[player:get_player_name()] == nil then
               balance = 0
          else
               balance = accounts.balance[player:get_player_name()]
          end
     end
     return balance
end

local credit = {}
function get_credit(player)
     for k, v in pairs(accounts.credit) do
          if accounts.credit[player:get_player_name()] == nil then
               credit = 0
          else
               credit = accounts.credit[player:get_player_name()]
          end
     end
     return credit
end

local monthly_payment = {}
function monthly_credit(player)
     if get_credit(player) == 0 then
          monthly_payment = 0
     else
          monthly_payment = math.floor(get_credit(player) * .04)
     end
     return monthly_payment
end

local withdrawn_money = minetest.create_detached_inventory("withdrawn_money", {
     allow_take = function(inv, listname, index, stack, player)
          return 30000
     end,
     on_take = function(inv, listname, index, stack, player) end,
})

withdrawn_money:set_size("main", 3)

local deposited_ones = {}
local ones = minetest.create_detached_inventory("ones", {
     allow_put = function(inv, listname, index, stack, player)
          return 30000
     end,
     on_put = function(inv, listname, index, stack, player)
          if stack:get_name() ~= "currency:minegeld" then
               local inventory = player:get_inventory()
               inventory:add_item("main", {name=stack:get_name(), count=stack:get_count()})
               inv:set_stack(listname, index, nil)
          end
          if stack:is_empty() == true then
               deposited_ones = 0
          else
               deposited_ones = stack:get_count()
          end
          inv:set_stack(listname, index, nil)
     end,
})

ones:set_size("main", 1)

local deposited_fives = {}
local fives = minetest.create_detached_inventory("fives", {
     allow_put = function(inv, listname, index, stack, player)
          return 30000
     end,
     on_put = function(inv, listname, index, stack, player)
          if stack:get_name() ~= "currency:minegeld_5" then
               local inventory = player:get_inventory()
               inventory:add_item("main", {name=stack:get_name(), count=stack:get_count()})
               inv:set_stack(listname, index, nil)
          end
          if stack:is_empty() == true then
               deposited_fives = 0
          else
               deposited_fives = (stack:get_count() * 5)
          end
          inv:set_stack(listname, index, nil)
     end,
})

fives:set_size("main", 1)

local deposited_tens = {}
local tens = minetest.create_detached_inventory("tens", {
     allow_put = function(inv, listname, index, stack, player)
          return 30000
     end,
     on_put = function(inv, listname, index, stack, player)
          if stack:get_name() ~= "currency:minegeld_10" then
               local inventory = player:get_inventory()
               inventory:add_item("main", {name=stack:get_name(), count=stack:get_count()})
               inv:set_stack(listname, index, nil)
          end
          if stack:is_empty() == true then
               deposited_tens = 0
          else
               deposited_tens = (stack:get_count() * 10)
          end
          inv:set_stack(listname, index, nil)
     end,
})

tens:set_size("main", 1)

function add_deposit(player, deposited_ones, deposited_fives, deposited_tens)
     if tonumber(deposited_ones) == nil then
          deposited_ones = 0
     end
     if tonumber(deposited_fives) == nil then
          deposited_fives = 0
     end
     if tonumber(deposited_tens) == nil then
          deposited_tens = 0
     end
     accounts.balance[player:get_player_name()] = accounts.balance[player:get_player_name()] + tonumber(deposited_ones) + tonumber(deposited_fives) + tonumber(deposited_tens)
     save_account()
end

function main_form(player)
     minetest.show_formspec(player:get_player_name(), "bank_accounts:atm_options",
          "size[8,8]" ..
          "button[1,.5;2,1;withdrawal;Withdraw]" ..
          "button[1,1.5;2,1;deposit;Deposit]" ..
          "button[1,2.5;3,1;monthly_credit;Pay Monthly Credit]" ..
          "label[4,1;Account Balance: $" .. get_balance(player) .."]" ..
          "label[4,1.5;Total Credit Debt: $" .. get_credit(player) .."]" ..
          "label[4,2;Monthly Credit Payment: $" .. monthly_credit(player) .."]" ..
          "button[1,3.5;3,1;credit_card;Get Credit Card]" ..
          "button[1,4.5;3,1;debit_card;Get Debit Card]" ..
          "button_exit[5,7;2,1;exit;Close]")
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
     accounts = read_account()
     if formname == "bank_accounts:atm_home" then
          if fields.enter then
               for k, v in pairs(accounts.pin) do
                    if fields.fourdigitpin == accounts.pin[player:get_player_name()] then
                         main_form(player)
                    end
               end
               if fields.fourdigitpin ~= accounts.pin[player:get_player_name()] then
                    minetest.chat_send_player(player:get_player_name(), "[ATM] Invalid Pin.")
               end
          end
     end
     if formname == "bank_accounts:atm_options" then
          if fields.withdrawal then
               minetest.show_formspec(player:get_player_name(), "bank_accounts:withdrawal",
                    "size[8,8]" ..
                    "field[2,4;5,1;money;Amount:;]" ..
                    "button[3,6;2,1;exit;Cancel]" ..
                    "button[5,6;2,1;enter;Enter]")
          end
          if fields.deposit then
               minetest.show_formspec(player:get_player_name(), "bank_accounts:deposit",
                    "size[8,8]" ..
                    "label[1,.5;$1]" ..
                    "label[2,.5;$5]" ..
                    "label[3,.5;$10]" ..
                    "list[detached:ones;main;.75,1;1,1]" ..
                    "list[detached:fives;main;1.75,1;1,1]" ..
                    "list[detached:tens;main;2.75,1;1,1]" ..
                    "list[current_player;main;0,3;8,4;]" ..
                    "button[5,7;2,1;enter;Enter]" ..
                    "button[3,7;2,1;exit;Cancel]")
          end
          if fields.monthly_credit then
               if get_credit(player) == 0 then
                    minetest.chat_send_player(player:get_player_name(), "[ATM] You do not have any credit debt.")
               else
                    minetest.show_formspec(player:get_player_name(), "bank_accounts:monthly_credit_payment",
                         "size[8,8]" ..
                         "button[1,1;3,1;month_button;Pay Monthly Amount]" ..
                         "label[1,2.5;Or]" ..
                         "field[1.5,4;4,1;number;Pay Larger Portion:;]" ..
                         "button[5,7;2,1;enter;Enter]")
               end
          end
          if fields.credit_card then
               local inv = player:get_inventory()
               inv:add_item("main", {name="bank_accounts:credit_card", count=1})
          end
          if fields.debit_card then
               local inv = player:get_inventory()
               inv:add_item("main", {name="bank_accounts:debit_card", count=1})
          end
     end
     if formname == "bank_accounts:withdrawal" then
          if fields.enter then
               if accounts.balance[player:get_player_name()] == nil then
                    minetest.chat_send_player(player:get_player_name(), "[ATM] Insufficient funds.")
               else
                    if fields.money == nil or fields.money == "" then
                         minetest.chat_send_player(player:get_player_name(), "[ATM] Account balance unchanged.")
                    elseif string.match(fields.money, "%a") or string.match(fields.money, "%a+") then
                         minetest.chat_send_player(player:get_player_name(), "[ATM] Account balance unchanged.")
                         return false
                    elseif accounts.balance[player:get_player_name()] < tonumber(fields.money) then
                         minetest.chat_send_player(player:get_player_name(), "[ATM] Insufficient funds.")
                    elseif accounts.balance[player:get_player_name()] >= tonumber(fields.money) then
                         accounts.balance[player:get_player_name()] = accounts.balance[player:get_player_name()] - tonumber(fields.money)
                         minetest.chat_send_player(player:get_player_name(), "[ATM] Funds Successfully Withdrawn!")
                         total_tens = math.floor(tonumber(fields.money) / 10)
                         total_fives = math.floor((tonumber(fields.money) - (total_tens * 10)) / 5)
                         total_ones = tonumber(fields.money) - ((total_fives * 5) + (total_tens * 10))
                         local inv = withdrawn_money
                         inv:add_item("main", {name="currency:minegeld_10", count=total_tens})
                         inv:add_item("main", {name="currency:minegeld_5", count=total_fives})
                         inv:add_item("main", {name="currency:minegeld", count=total_ones})
                         minetest.show_formspec(player:get_player_name(), "bank_accounts:withdrawn_money",
                              "size[8,8]" ..
                              "list[detached:withdrawn_money;main;1,1;3,1]" ..
                              "list[current_player;main;0,3;8,4;]" ..
                              "button[3,7;2,1;exit;Home]")
                         save_account()
                    end
               end
          end
          if fields.exit then
               main_form(player)
          end
     end
     if formname == "bank_accounts:withdrawn_money" then
          if fields.exit then
               main_form(player)
          end
     end
     if formname == "bank_accounts:deposit" then
          if fields.enter then
               add_deposit(player, deposited_ones, deposited_fives, deposited_tens)
               main_form(player)
          end
          if fields.exit then
               main_form(player)
          end
     end
     if formname == "bank_accounts:monthly_credit_payment" then
          if fields.month_button then
               for k, v in pairs(accounts.balance) do
                    if accounts.balance[player:get_player_name()] == nil then
                         minetest.chat_send_player(player:get_player_name(), "[ATM] Insufficient funds.")
                    else
                         if accounts.balance[player:get_player_name()] >= (get_credit(player) * .04) then
                              for k, v in pairs(accounts.credit) do
                                   accounts.credit[player:get_player_name()] = accounts.credit[player:get_player_name()] - math.floor(get_credit(player) * .04)
                                   minetest.chat_send_player(player:get_player_name(), "[ATM] Monthly credit payment successfully paid.")
                              end
                              accounts.balance[player:get_player_name()] = accounts.balance[player:get_player_name()] - math.floor(get_credit(player) * .04)
                              save_account()
                         elseif accounts.balance[player:get_player_name()] < (get_credit(player) * .04) then
                              minetest.chat_send_player(player:get_player_name(), "[ATM] Insufficient funds.")
                         end
                    end
                    main_form(player)
               end
          end
          if fields.enter then
               if accounts.balance[player:get_player_name()] == nil then
                    minetest.chat_send_player(player:get_player_name(), "[ATM] Insufficient funds.")
               else
                    for k, v in pairs(accounts.credit) do
                         if string.match(fields.number, "%a") or string.match(fields.number, "%a+") then
                              minetest.chat_send_player(player:get_player_name(), "[ATM] Account balance and credit unchanged.")
                         elseif fields.number == "" or fields.number == nil then
                              minetest.chat_send_player(player:get_player_name(), "[ATM] No amount input.")
                         else
                              if tonumber(fields.number) > accounts.credit[player:get_player_name()] then
                                   minetest.chat_send_player(player:get_player_name(), "[ATM] You don't have that much credit debt.")
                              else
                                   if tonumber(fields.number) >= math.floor(get_credit(player) * .04) then
                                        for k, v in pairs(accounts.balance) do
                                             if accounts.balance[player:get_player_name()] >= tonumber(fields.number) then
                                                  for k, v in pairs(accounts.credit) do
                                                       accounts.credit[player:get_player_name()] = accounts.credit[player:get_player_name()] - tonumber(fields.number)
                                                       minetest.chat_send_player(player:get_player_name(), "[ATM] $" .. tonumber(fields.number) .. " of credit debt successfully paid.")
                                                  end
                                                  accounts.balance[player:get_player_name()] = accounts.balance[player:get_player_name()] - tonumber(fields.number)
                                                  save_account()
                                             elseif accounts.balance[player:get_player_name()] < tonumber(fields.number) then
                                                  minetest.chat_send_player(player:get_player_name(), "[ATM] Insufficient funds.")
                                             end
                                        end
                                        main_form(player)
                                   elseif tonumber(fields.number) < math.floor(get_credit(player) * .04) then
                                        minetest.chat_send_player(player:get_player_name(), "[ATM] Payment must be larger than the minimum monthly payment.")
                                   elseif string.match(fields.number, "%a") or string.match(fields.number, "%a+") then
                                        minetest.chat_send_player(player:get_player_name(), "[ATM] Account balance and credit unchanged.")
                                   end
                              end
                         end
                    end
               end
          end
     end
end)
