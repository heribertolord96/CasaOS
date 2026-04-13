package v1

import (
	"bytes"
	"encoding/json"
	"net"
	"net/http"
	"net/url"
	"os/exec"
	"strconv"
	"strings"
	"time"

	common_err "github.com/IceWhaleTech/CasaOS-Common/utils/common_err"
	"github.com/IceWhaleTech/CasaOS-Common/utils/logger"
	sshHelper "github.com/IceWhaleTech/CasaOS-Common/utils/ssh"
	"github.com/IceWhaleTech/CasaOS/pkg/utils"
	"github.com/labstack/echo/v4"

	"github.com/gorilla/websocket"
	"go.uber.org/zap"

	modelCommon "github.com/IceWhaleTech/CasaOS-Common/model"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:   1024,
	WriteBufferSize:  1024,
	CheckOrigin:      websocketSameOriginHost,
	HandshakeTimeout: time.Duration(time.Second * 5),
}

// websocketSameOriginHost rejects cross-origin browser WebSockets when an Origin header is present.
func websocketSameOriginHost(r *http.Request) bool {
	origin := r.Header.Get("Origin")
	if origin == "" {
		return true
	}
	u, err := url.Parse(origin)
	if err != nil {
		return false
	}
	host := r.Host
	if h, _, err := net.SplitHostPort(host); err == nil {
		host = h
	}
	return strings.EqualFold(u.Hostname(), host)
}

func PostSshLogin(ctx echo.Context) error {
	j := make(map[string]string)
	ctx.Bind(&j)
	userName := j["username"]
	password := j["password"]
	port := j["port"]
	if userName == "" || password == "" || port == "" {
		return ctx.JSON(common_err.CLIENT_ERROR, modelCommon.Result{Success: common_err.INVALID_PARAMS, Message: common_err.GetMsg(common_err.INVALID_PARAMS), Data: "Username or password or port is empty"})
	}
	_, err := sshHelper.NewSshClient(userName, password, port)
	if err != nil {
		logger.Error("connect ssh error", zap.Any("error", err))
		return ctx.JSON(common_err.CLIENT_ERROR, modelCommon.Result{Success: common_err.CLIENT_ERROR, Message: common_err.GetMsg(common_err.CLIENT_ERROR), Data: "Please check if the username and port are correct, and make sure that ssh server is installed."})
	}
	return ctx.JSON(common_err.SUCCESS, modelCommon.Result{Success: common_err.SUCCESS, Message: common_err.GetMsg(common_err.SUCCESS)})
}

type sshWsCreds struct {
	Username string `json:"username"`
	Password string `json:"password"`
	Port     string `json:"port"`
}

func WsSsh(ctx echo.Context) error {
	_, e := exec.LookPath("ssh")
	if e != nil {
		return ctx.JSON(common_err.SERVICE_ERROR, modelCommon.Result{Success: common_err.SERVICE_ERROR, Message: common_err.GetMsg(common_err.SERVICE_ERROR), Data: "ssh server not found"})
	}

	userName := ctx.QueryParam("username")
	password := ctx.QueryParam("password")
	port := ctx.QueryParam("port")
	wsConn, err := upgrader.Upgrade(ctx.Response().Writer, ctx.Request(), nil)
	if err != nil {
		return err
	}
	logBuff := new(bytes.Buffer)

	quitChan := make(chan bool, 3)
	cols, _ := strconv.Atoi(utils.DefaultQuery(ctx, "cols", "200"))
	rows, _ := strconv.Atoi(utils.DefaultQuery(ctx, "rows", "32"))

	// Prefer first WebSocket JSON frame so secrets are not placed in the URL (logs, Referer, history).
	if password == "" {
		_ = wsConn.SetReadDeadline(time.Now().Add(30 * time.Second))
		_, msg, rerr := wsConn.ReadMessage()
		if rerr != nil {
			return nil
		}
		var creds sshWsCreds
		if json.Unmarshal(msg, &creds) == nil && creds.Password != "" {
			userName, password, port = creds.Username, creds.Password, creds.Port
		}
		_ = wsConn.SetReadDeadline(time.Time{})
	}

	if userName == "" || password == "" || port == "" {
		_ = wsConn.WriteMessage(websocket.TextMessage, []byte("username or password or port is empty"))
		return nil
	}

	client, err := sshHelper.NewSshClient(userName, password, port)
	if err != nil {
		_ = wsConn.WriteMessage(websocket.TextMessage, []byte(err.Error()))
		_ = wsConn.WriteMessage(websocket.TextMessage, []byte("\r\n\x1b[0m"))
		return nil
	}
	if client == nil {
		_ = wsConn.WriteMessage(websocket.TextMessage, []byte("ssh connection failed"))
		return nil
	}
	defer client.Close()

	ssConn, _ := sshHelper.NewSshConn(cols, rows, client)
	defer ssConn.Close()

	go ssConn.ReceiveWsMsg(wsConn, logBuff, quitChan)
	go ssConn.SendComboOutput(wsConn, quitChan)
	go ssConn.SessionWait(quitChan)

	<-quitChan
	return nil
}
