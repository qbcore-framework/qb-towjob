local Translations = {
    error = {
        finish_work = "Maak eerst al je werk af",
        vehicle_not_correct = "Dit is niet het juiste voertuig",
        failed = "Tis mislukt",
        not_towing_vehicle = "Je moet in je takeldienst voertuig zitten",
        too_far_away = "Je bent iets te ver weg",
        no_work_done = "Er is nog geen werk",
        no_deposit = "$%{value} Waarborg nodig",
    },
    success = {
        paid_with_cash = "$%{value} Waarborg betaald met cash",
        paid_with_bank = "$%{value} Waarborg betaald van de bank",
        refund_to_cash = "$%{value} Waarborg betaald met cash",
        you_earned = "Je hebt €%{value} verdiend",
    },
    menu = {
        header = "Beschikbare voertuigen",
        close_menu = "⬅ Sluit Menu",
    },
    mission = {
        delivered_vehicle = "Je hebt een voertuig afgeleverd",
        get_new_vehicle = "Je kan een nieuw voertuig ophalen",
        towing_vehicle = "Voertuig takelen..",
        goto_depot = "Breng het voertuig naar den depot",
        vehicle_towed = "Voertuig getakeld",
        untowing_vehicle = "Zet het voertuig terug op de grond",
        vehicle_takenoff = "Voertuig is succesvol op de grond geplaatst",
    },
    info = {
        tow = "Takel een voertuig op uw takeldienstding",
        toggle_npc = "Zet NPC job aan",
        skick = "Niet exploiten, voale vettigen das!",
    },
    label = {
        payslip = "Betalingsbewijs",
        vehicle = "Voertuig",
        npcz = "NPCZone",
    }
}

if GetConvar('qb_locale', 'en') == 'nl' then
    Lang = Lang or Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
