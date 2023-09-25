local Translations = {
    error = {
        finish_work = "Termine todo o seu trabalho primeiro",
        vehicle_not_correct = "Este não é o veículo correto",
        failed = "Você falhou",
        not_towing_vehicle = "Você deve estar em seu Veículo de Reboque",
        too_far_away = "Você está muito longe",
        no_work_done = "Você não fez nenhum trabalho ainda",
        no_deposit = "Depósito de $%{value} necessário",
    },
    success = {
        paid_with_cash = "Depósito de $%{value} pago em dinheiro",
        paid_with_bank = "Depósito de $%{value} pago da conta bancária",
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
        goto_depot = "Leve o veículo para o Depósito Hayes",
        vehicle_towed = "Veículo rebocado",
        untowing_vehicle = "Remover o veículo",
        vehicle_takenoff = "Veículo retirado",
    },
    info = {
        tow = "Coloque um carro na parte de trás do seu caminhão de plataforma",
        toggle_npc = "Alternar Trabalho de NPC",
        skick = "Tentativa de abuso de exploração",
    },
    label = {
        payslip = "Contra-Cheque",
        vehicle = "Veículo",
        npcz = "Zona de NPC",
    }
}

if GetConvar('qb_locale', 'en') == 'pt-br' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
