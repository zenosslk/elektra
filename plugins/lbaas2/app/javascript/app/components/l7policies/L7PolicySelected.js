import { useEffect, useState, useMemo } from "react"
import CopyPastePopover from "../shared/CopyPastePopover"
import StateLabel from "../shared/StateLabel"
import StatusLabel from "../shared/StatusLabel"
import StaticTags from "../StaticTags"
import useL7Policy from "../../../lib/hooks/useL7Policy"
import { Link } from "react-router-dom"
import { addNotice, addError } from "lib/flashes"
import { ErrorsList } from "lib/elektra-form/components/errors_list"
import useCommons from "../../../lib/hooks/useCommons"
import useListener from "../../../lib/hooks/useListener"
import SmartLink from "../shared/SmartLink"
import { policy } from "policy"
import { scope } from "ajax_helper"
import Log from "../shared/logger"

const L7PolicySelected = ({ props, listenerID, l7Policy, onBackLink }) => {
  const { actionRedirect, deleteL7Policy, persistL7Policy } = useL7Policy()
  const { matchParams, errorMessage } = useCommons()
  const { persistListener } = useListener()
  const [loadbalancerID, setLoadbalancerID] = useState(null)
  let polling = null

  useEffect(() => {
    const params = matchParams(props)
    setLoadbalancerID(params.loadbalancerID)

    if (l7Policy.provisioning_status.includes("PENDING")) {
      startPolling(5000)
    } else {
      startPolling(30000)
    }

    return function cleanup() {
      stopPolling()
    }
  })

  const startPolling = (interval) => {
    // do not create a new polling interval if already polling
    if (polling) return
    polling = setInterval(() => {
      Log.debug(
        "Polling l7 policy selected -->",
        l7Policy.id,
        " with interval -->",
        interval
      )
      persistL7Policy(
        loadbalancerID,
        listenerID,
        l7Policy.id
      ).catch((error) => {})
    }, interval)
  }

  const stopPolling = () => {
    Log.debug("stop polling for listener id -->", l7Policy.id)
    clearInterval(polling)
    polling = null
  }

  const canDelete = useMemo(
    () =>
      policy.isAllowed("lbaas2:l7policy_delete", {
        target: { scoped_domain_name: scope.domain },
      }),
    [scope.domain]
  )

  const handleDelete = (e) => {
    if (e) {
      e.stopPropagation()
      e.preventDefault()
    }
    const l7policyID = l7Policy.id
    const l7policyName = l7Policy.name
    return deleteL7Policy(loadbalancerID, listenerID, l7policyID, l7policyName)
      .then((response) => {
        addNotice(
          <React.Fragment>
            L7 Policy <b>{l7policyName}</b> ({l7policyID}) is being deleted.
          </React.Fragment>
        )
        // fetch the listener again containing the new policy so it gets updated fast
        persistListener(loadbalancerID, listenerID)
          .then(() => {})
          .catch((error) => {})
        // on remove go back to policy list
        onBackLink()
      })
      .catch((error) => {
        addError(
          React.createElement(ErrorsList, {
            errors: errorMessage(error.response),
          })
        )
      })
  }

  return (
    <React.Fragment>
      <div className="selected-l7policy-head">
        <div className="row selected-l7policy-head-content">
          <div className="col-md-12">
            <div className="display-flex">
              <Link className="back-link" to="#" onClick={onBackLink}>
                <i className="fa fa-chevron-circle-left"></i>
                Back to L7 Policies
              </Link>
              <div className="btn-group btn-right">
                <button
                  className="btn btn-default btn-xs dropdown-toggle"
                  type="button"
                  data-toggle="dropdown"
                  aria-expanded={true}
                >
                  <span className="fa fa-cog"></span>
                </button>
                <ul className="dropdown-menu dropdown-menu-right" role="menu">
                  <li>
                    <SmartLink
                      onClick={handleDelete}
                      isAllowed={canDelete}
                      notAllowedText="Not allowed to delete. Please check with your administrator."
                    >
                      Delete
                    </SmartLink>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="multiple-subtable-scroll-body">
        <div className="selected-l7policy-entry">
          <div className="row">
            <div className="col-md-12">
              <b>Name/ID:</b>
            </div>
          </div>
          <div className="row">
            <div className="col-md-12">{l7Policy.name || l7Policy.id}</div>
          </div>
          {l7Policy.name && (
            <div className="row">
              <div className="col-md-12 text-nowrap">
                <small className="info-text">
                  {
                    <CopyPastePopover
                      text={l7Policy.id}
                      bsClass="cp copy-paste-ids"
                    />
                  }
                </small>
              </div>
            </div>
          )}
        </div>

        <div className="selected-l7policy-entry">
          <div className="row">
            <div className="col-md-12">
              <b>Description:</b>
            </div>
          </div>
          <div className="row">
            <div className="col-md-12">{l7Policy.description}</div>
          </div>
        </div>

        <div className="selected-l7policy-entry">
          <div className="row">
            <div className="col-md-12">
              <b>State:</b>
            </div>
          </div>
          <div className="row">
            <div className="col-md-12">
              <StateLabel label={l7Policy.operating_status} />
            </div>
          </div>
        </div>

        <div className="selected-l7policy-entry">
          <div className="row">
            <div className="col-md-12">
              <b>Prov. Status:</b>
            </div>
          </div>
          <div className="row">
            <div className="col-md-12">
              <StatusLabel label={l7Policy.provisioning_status} />
            </div>
          </div>
        </div>

        <div className="selected-l7policy-entry">
          <div className="row">
            <div className="col-md-12">
              <b>Tags:</b>
            </div>
          </div>
          <div className="row">
            <div className="col-md-12">
              <StaticTags tags={l7Policy.tags} />
            </div>
          </div>
        </div>

        <div className="selected-l7policy-entry">
          <div className="row">
            <div className="col-md-12">
              <b>Position:</b>
            </div>
          </div>
          <div className="row">
            <div className="col-md-12">{l7Policy.position}</div>
          </div>
        </div>

        <div className="selected-l7policy-entry">
          <div className="row">
            <div className="col-md-12">
              <b>Action/Redirect:</b>
            </div>
          </div>
          <div className="row">
            <div className="col-md-12">
              {l7Policy.action}
              {actionRedirect(l7Policy.action).map((redirect, index) => (
                <div key={index}>
                  <ul>
                    <li>{redirect.label}: </li>
                    {redirect.value === "redirect_prefix" ||
                    redirect.value === "redirect_url" ? (
                      <CopyPastePopover
                        text={l7Policy[redirect.value]}
                        shouldPopover={false}
                        bsClass="cp label-right"
                      />
                    ) : (
                      <span>{l7Policy[redirect.value]}</span>
                    )}
                  </ul>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="selected-l7policy-entry">
          <div className="row">
            <div className="col-md-12">
              <b>L7 Rules:</b>
            </div>
          </div>
          <div className="row">
            <div className="col-md-12">{l7Policy.rules.length}</div>
          </div>
        </div>
      </div>
    </React.Fragment>
  )
}

export default L7PolicySelected
