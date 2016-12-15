minetest.register_craftitem("bank_accounts:credit_card", {
     description = "Credit Card",
     inventory_image = "credit_card.png",
     groups = {not_in_creative_inventory=1},
          stack_max = 1,
})

minetest.register_craftitem("bank_accounts:debit_card", {
     description = "Debit Card",
     inventory_image = "debit_card.png",
     groups = {not_in_creative_inventory=1},
          stack_max = 1,
})
