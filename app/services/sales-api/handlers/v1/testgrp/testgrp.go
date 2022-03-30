package testgrp

import (
	"context"
	"net/http"

	"github.com/ardanlabs/service/foundation/web"
	"go.uber.org/zap"
)

type Handlers struct {
	Log *zap.SugaredLogger
}

func (h Handlers) Test(ctx context.Context, w http.ResponseWriter, r *http.Request) error {
	status := struct {
		Status string
	}{
		Status: "Ok",
	}

	httpStatus := http.StatusOK
	h.Log.Infow("test", "statusCode", httpStatus, "method", r.Method, "path", r.URL.Path, "remoteaddr", r.RemoteAddr)

	return web.Respond(ctx, w, status, httpStatus)
}
