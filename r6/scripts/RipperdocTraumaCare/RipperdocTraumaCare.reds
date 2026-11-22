// Ripperdoc Trauma Care
//
// Ripperdocs can treat Dark Future's Injury condition. When V is injured, the ripperdoc screen
// shows a "Treat injuries" button with the price. Treatment clears every Injury level and the
// progress toward the next one, through Dark Future's own cure path (the one its Trauma Kit uses),
// so Dark Future's status effects, HUD and notifications update as usual.
//
// Requires Codeware (button, popup) and Dark Future. Without Dark Future it compiles and does
// nothing. Settings are on its Mod Settings page when Mod Settings is installed.
module RipperdocTraumaCare

import Codeware.UI.*

@if(ModuleExists("DarkFuture.Conditions"))
import DarkFuture.Conditions.DFInjuryConditionSystem

public class RTCSettings extends ScriptableSystem {
    @runtimeProperty("ModSettings.mod", "Ripperdoc Trauma Care")
    @runtimeProperty("ModSettings.displayName", "Enable")
    @runtimeProperty("ModSettings.description", "Show the Treat injuries option at ripperdocs.")
    public let enabled: Bool = true;

    @runtimeProperty("ModSettings.mod", "Ripperdoc Trauma Care")
    @runtimeProperty("ModSettings.displayName", "Price per Injury level")
    @runtimeProperty("ModSettings.description", "Eurodollars per full Injury level. Progress toward the next level is charged pro rata.")
    @runtimeProperty("ModSettings.step", "250")
    @runtimeProperty("ModSettings.min", "0")
    @runtimeProperty("ModSettings.max", "25000")
    public let pricePerLevel: Int32 = 2000;

    @runtimeProperty("ModSettings.mod", "Ripperdoc Trauma Care")
    @runtimeProperty("ModSettings.displayName", "Minimum fee")
    @runtimeProperty("ModSettings.description", "The least a treatment costs, however small the injury.")
    @runtimeProperty("ModSettings.step", "100")
    @runtimeProperty("ModSettings.min", "0")
    @runtimeProperty("ModSettings.max", "10000")
    public let minimumFee: Int32 = 500;

    @runtimeProperty("ModSettings.mod", "Ripperdoc Trauma Care")
    @runtimeProperty("ModSettings.displayName", "Street Cred discount (% at max)")
    @runtimeProperty("ModSettings.description", "Discount at Street Cred 50, scaling linearly from 0 at Street Cred 1. Ripperdocs give regulars a better rate.")
    @runtimeProperty("ModSettings.step", "5")
    @runtimeProperty("ModSettings.min", "0")
    @runtimeProperty("ModSettings.max", "90")
    public let streetCredDiscount: Int32 = 30;

    private func OnAttach() -> Void {
        ModSettings.RegisterListenerToClass(this);
    }

    private func OnDetach() -> Void {
        ModSettings.UnregisterListenerToClass(this);
    }

    public static func Get(game: GameInstance) -> ref<RTCSettings> {
        return GameInstance.GetScriptableSystemsContainer(game).Get(n"RipperdocTraumaCare.RTCSettings") as RTCSettings;
    }
}

// --- Dark Future bridge (the only code that touches Dark Future) ------------------------------

public abstract class RTCInjury {
    // Injury to treat, in Dark Future's units: 100 per level plus progress toward the next.
    @if(ModuleExists("DarkFuture.Conditions"))
    public static func Amount() -> Float {
        let injury = DFInjuryConditionSystem.Get();
        if !IsDefined(injury) || !injury.GetSystemToggleSettingValue() {
            return 0.0;
        }
        return Cast<Float>(injury.GetConditionLevel()) * 100.0 + injury.accumulatedPercentTowardNextLevel;
    }

    @if(!ModuleExists("DarkFuture.Conditions"))
    public static func Amount() -> Float {
        return 0.0;
    }

    public static func Level() -> Int32 {
        return CeilF(RTCInjury.Amount() / 100.0);
    }

    @if(ModuleExists("DarkFuture.Conditions"))
    public static func TreatAll() -> Void {
        let amount = RTCInjury.Amount();
        if amount > 0.0 {
            DFInjuryConditionSystem.Get().RestoreCondition(amount);
        }
    }

    @if(!ModuleExists("DarkFuture.Conditions"))
    public static func TreatAll() -> Void {}
}

// --- Ripperdoc screen ---------------------------------------------------------------------

public class RTCPanel {
    private let m_owner: wref<RipperDocGameController>;
    private let m_button: ref<SimpleButton>;
    private let m_token: ref<inkGameNotificationToken>;
    private let m_price: Int32;

    public static func Create(owner: ref<RipperDocGameController>) -> ref<RTCPanel> {
        let self = new RTCPanel();
        self.m_owner = owner;
        let button = SimpleButton.Create();
        button.SetWidth(560.0);
        let root = button.GetRootWidget();
        root.SetAnchor(inkEAnchor.BottomRight);
        root.SetAnchorPoint(Vector2(1.0, 1.0));
        // Above the bottom-right corner, left of where loadout/slot mods usually put theirs.
        root.SetMargin(inkMargin(0.0, 0.0, 560.0, 190.0));
        button.Reparent(owner.GetRootCompoundWidget());
        button.RegisterToCallback(n"OnBtnClick", self, n"OnTreatClick");
        self.m_button = button;
        self.Refresh();
        return self;
    }

    private func Game() -> GameInstance {
        return this.m_owner.GetPlayerControlledObject().GetGame();
    }

    private func Player() -> ref<GameObject> {
        return this.m_owner.GetPlayerControlledObject();
    }

    public func Price() -> Int32 {
        let s = RTCSettings.Get(this.Game());
        let perLevel = IsDefined(s) ? s.pricePerLevel : 2000;
        let minimum = IsDefined(s) ? s.minimumFee : 500;
        let discountMax = IsDefined(s) ? s.streetCredDiscount : 30;
        let price = Cast<Float>(perLevel) * RTCInjury.Amount() / 100.0;
        let cred = GameInstance.GetStatsSystem(this.Game()).GetStatValue(Cast<StatsObjectID>(this.Player().GetEntityID()), gamedataStatType.StreetCred);
        let discount = ClampF((cred - 1.0) / 49.0, 0.0, 1.0) * Cast<Float>(discountMax) / 100.0;
        price = price * (1.0 - discount);
        return Max(RoundF(price), minimum);
    }

    public func Refresh() -> Void {
        let s = RTCSettings.Get(this.Game());
        let show = (!IsDefined(s) || s.enabled) && RTCInjury.Amount() > 0.0;
        this.m_button.GetRootWidget().SetVisible(show);
        if show {
            this.m_price = this.Price();
            this.m_button.SetText(s"TREAT INJURIES  €$\(this.m_price)");
        }
    }

    protected cb func OnTreatClick(widget: wref<inkWidget>) -> Bool {
        if IsDefined(this.m_token) {
            return false;
        }
        this.m_price = this.Price();
        let level = RTCInjury.Level();
        let message = s"Patch up V's injuries (Injury \(level)) for €$\(this.m_price)? This clears every Injury level, like a full course of Trauma Kits.";
        this.m_token = GenericMessageNotification.Show(this.m_owner, "Trauma care", message, GenericMessageNotificationType.YesNo);
        this.m_token.RegisterListener(this, n"OnTreatConfirmed");
        return true;
    }

    protected cb func OnTreatConfirmed(data: ref<inkGameNotificationData>) -> Bool {
        this.m_token = null;
        let result = data as GenericMessageNotificationCloseData;
        if !IsDefined(result) || NotEquals(result.result, GenericMessageNotificationResult.Yes) {
            return false;
        }
        let ts = GameInstance.GetTransactionSystem(this.Game());
        let price = this.Price();
        if ts.GetItemQuantity(this.Player(), MarketSystem.Money()) < price {
            let notification = new UIMenuNotificationEvent();
            notification.m_notificationType = UIMenuNotificationType.VNotEnoughMoney;
            this.m_owner.QueueEvent(notification);
            return false;
        }
        ts.RemoveItem(this.Player(), MarketSystem.Money(), price);
        RTCInjury.TreatAll();
        this.m_owner.RTCUpdateMoney();
        this.Refresh();
        return true;
    }
}

@addField(RipperDocGameController)
private let m_rtcPanel: ref<RTCPanel>;

@wrapMethod(RipperDocGameController)
protected cb func OnInitialize() -> Bool {
    let result = wrappedMethod();
    // Only the real ripperdoc (not the character menu's cyberware screen), only with Dark Future.
    if Equals(this.m_screen, CyberwareScreenType.Ripperdoc) && RTCInjury.Amount() > 0.0 {
        this.m_rtcPanel = RTCPanel.Create(this);
    }
    return result;
}

// Refreshes the money shown on the ripperdoc screen (same signal Cyberware-EX uses).
@addMethod(RipperDocGameController)
public func RTCUpdateMoney() -> Void {
    let def = GetAllBlackboardDefs().UI_Vendor;
    let bb = GameInstance.GetBlackboardSystem(this.GetPlayerControlledObject().GetGame()).Get(def);
    bb.SignalVariant(def.VendorData);
}
