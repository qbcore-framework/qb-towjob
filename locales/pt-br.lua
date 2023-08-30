local Translations = {
    error = {
        finish_work = "Termine todo o seu trabalho primeiro",
        vehicle_not_correct = "Este não é o veículo correto",
        failed = "Você falhou",
        not_towing_vehicle = "Você deve estar em seu veículo de reboque",
        too_far_away = "Você está muito longe",
        no_work_done = "Você ainda não fez nenhum trabalho",
        no_deposit = "Depósito de $%{value} necessário",
    },
    success = {
        paid_with_cash = "Depósito de $%{value} pago em dinheiro",
        paid_with_bank = "Depósito de $%{value} pago do banco",
        refund_to_cash = "Depósito de $%{value} reembolsado em dinheiro",
        you_earned = "Você ganhou $%{value}",
    },
    menu = {
        header = "Caminhões Disponíveis",
        close_menu = "⬅ Fechar Menu",
    },
    mission = {
        delivered_vehicle = "Você entregou um veículo",
        get_new_vehicle = "Um novo veículo pode ser retirado",
        towing_vehicle = "Içando o veículo...",
        goto_depot = "Leve o veículo para o depósito Hayes",
        vehicle_towed = "Veículo rebocado",
        untowing_vehicle = "Removendo o veículo",
        vehicle_takenoff = "Veículo retirado",
    },
    info = {
        tow = "Coloque um carro na parte de trás de seu reboque",
        toggle_npc = "Alternar Trabalho de NPC",
        skick = "Tentativa de abuso de exploração",
    },
    label = {
        payslip = "Contra-Cheque",
        vehicle = "Veículo",
        npcz = "Zona de NPC",
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
