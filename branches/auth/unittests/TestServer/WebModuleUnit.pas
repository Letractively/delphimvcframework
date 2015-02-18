unit WebModuleUnit;

interface

uses System.SysUtils,
  System.Classes,
  Web.HTTPApp,
  MVCFramework;

type
  Twm = class(TWebModule)
    procedure WebModuleCreate(Sender: TObject);
  private
    MVCEngine: TMVCEngine;
  end;

var
  WebModuleClass: TComponentClass = Twm;

implementation

{$R *.dfm}

uses
  TestServerControllerU, TestServerControllerExceptionU, SpeedMiddlewareU,
  MVCFramework.Middleware.Authentication, System.Generics.Collections;

procedure Twm.WebModuleCreate(Sender: TObject);
begin
  MVCEngine := TMVCEngine.Create(self);
  MVCEngine.AddController(TTestServerController).AddController(TTestPrivateServerController)
    .AddController(TTestServerControllerExceptionAfterCreate)
    .AddController(TTestServerControllerExceptionBeforeDestroy)
    .AddMiddleware(TMVCSpeedMiddleware.Create).AddMiddleware(TMVCAuthenticationMiddleware.Create(
    procedure(const AUserName, APassword: string; AControllerQualifiedClassName,
      AActionName: string; AUserRoles: TList<string>; var AIsValid: Boolean)
    begin
      AUserRoles.Clear;
      AIsValid := False;
      if AUserName = 'user1' then
      begin
        AIsValid := True;
        AUserRoles.Add('role1');
      end;
      if AUserName = 'user2' then
      begin
        AIsValid := True;
        AUserRoles.Add('role2');
      end;
    end,
    procedure(AContext: TWebContext; const AControllerQualifiedClassName: string;
      const AActionName: string; var AIsAuthorized: Boolean)
    begin
      if AActionName = 'OnlyRole1' then
        AIsAuthorized := AContext.LoggedUser.Roles.Contains('role1');

      if AActionName = 'OnlyRole2' then
        AIsAuthorized := AContext.LoggedUser.Roles.Contains('role2');
    end));

  MVCEngine.Config[TMVCConfigKey.StompServer] := 'localhost';
  MVCEngine.Config[TMVCConfigKey.StompServerPort] := '61613';
  MVCEngine.Config[TMVCConfigKey.StompUserName] := 'guest';
  MVCEngine.Config[TMVCConfigKey.StompPassword] := 'guest';
  MVCEngine.Config[TMVCConfigKey.Messaging] := 'false';
end;

end.