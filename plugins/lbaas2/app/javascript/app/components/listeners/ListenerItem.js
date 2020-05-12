import React from 'react';
import { Link } from 'react-router-dom';
import { Highlighter } from 'react-bootstrap-typeahead'
import StateLabel from '../StateLabel'
import StaticTags from '../StaticTags';
import { Tooltip, OverlayTrigger } from 'react-bootstrap';
import CopyPastePopover from '../shared/CopyPastePopover'
import CachedInfoPopover from '../shared/CachedInforPopover';
import CachedInfoPopoverContent from './CachedInfoPopoverContent'
import CachedInfoPopoverContentContainers from '../shared/CachedInfoPopoverContentContainers'
import useListener from '../../../lib/hooks/useListener'

const MyHighlighter = ({search,children}) => {
  if(!search || !children) return children
  return <Highlighter search={search}>{children+''}</Highlighter>
}

const ListenerItem = ({listener, searchTerm, onSelectListener, disabled}) => {
  const {certificateContainerRelation} = useListener()

  const onClick = (e) => {
    if (e) {
      e.stopPropagation()
      e.preventDefault()
    }
    onSelectListener(listener.id)
  }

  const handleDelete = () => {
  }


  const displayName = () => {
    const name = listener.name || listener.id
    const cutName = <CopyPastePopover text={name} size={20} sliceType="MIDDLE" shouldPopover={false} shouldCopy={false}/>
    if (disabled) {
        return <span className="info-text">{cutName}</span>
    } else {
      if (searchTerm) {
        return <Link to="#" onClick={onClick}>
                <MyHighlighter search={searchTerm}>{name}</MyHighlighter>
              </Link>
      } else {
        return <Link to="#" onClick={onClick}>
                <MyHighlighter search={searchTerm}>{cutName}</MyHighlighter>
              </Link>
      }
    }
  }
  const displayID = () => {
    if (listener.name) {
      if (disabled) {
        return <span className="info-text"><CopyPastePopover text={listener.id} size={12} sliceType="MIDDLE" bsClass="cp copy-paste-ids"/></span>
      } else {
        if (searchTerm) {
          return <React.Fragment><br/><span className="info-text"><MyHighlighter search={searchTerm}>{listener.id}</MyHighlighter></span></React.Fragment>
        } else {
          return <CopyPastePopover text={listener.id} size={12} sliceType="MIDDLE" bsClass="cp copy-paste-ids"/>
        }        
      }
    }
  }
  const displayDescription = () => {
    const description = <CopyPastePopover text={listener.description} size={20} shouldCopy={false} shouldPopover={true}/>
    if (disabled) {
      return description
    } else {
      if (searchTerm) {
        return <MyHighlighter search={searchTerm}>{listener.description}</MyHighlighter>
      } else {
        return description
      }
    }
  }



  const collectContainers = () => {
    const containers = [
      {name:"Certificate Container", ref: listener.default_tls_container_ref},
      {name:"SNI Containers", refList: listener.sni_container_refs},
      {name:"Client Authentication Container", ref: listener.client_ca_tls_container_ref}
    ]
    var filteredContainers = containers.reduce( (filteredContainers, item) => {
      if(item.ref && item.ref.length > 0 || item.refList && item.refList.length > 0) {
        filteredContainers.push(item)
      }
      return filteredContainers
    },[])
    return filteredContainers
  }

  const displayProtocol = () => {
    const containers = collectContainers()
    return (
      <React.Fragment>
        {listener.protocol}
        {certificateContainerRelation(listener.protocol) &&
          <div className="display-flex">
            <span>Client Auth: </span>
            <span className="label-right">{listener.client_authentication}</span>
          </div>
        }
        {certificateContainerRelation(listener.protocol) && 
          <div className="display-flex">
            <span>Secrets: </span>
            <div className="label-right">
              <CachedInfoPopover  popoverId={"listeners-secrets-popover-"+listener.id} 
                buttonName={containers.length} 
                title={<React.Fragment>Secrets</React.Fragment>}
                content={<CachedInfoPopoverContentContainers containers={containers} />} />
            </div>
          </div>
        }
      </React.Fragment>
    )
  }

  const l7PolicyIDs = listener.l7policies.map(l7p => l7p.id)
  return ( 
    <tr className={disabled ? "active" : ""}>
      <td className="snug-nowrap">
        {displayName()}
        {displayID()}
        {displayDescription()}
      </td>
      <td>
        <div><StateLabel placeholder={listener.operating_status} path="" /></div>
        <div><StateLabel placeholder={listener.provisioning_status} path=""/></div>
      </td>
      <td>
        <StaticTags tags={listener.tags} />
      </td>
      <td>
        {displayProtocol()}
      </td>
      <td>{listener.protocol_port}</td>
      <td>
        {listener.default_pool_id ?
          <OverlayTrigger placement="top" overlay={<Tooltip id="defalult-pool-tooltip">{listener.default_pool_id}</Tooltip>}>
            <i className="fa fa-check" />
          </OverlayTrigger>  
          :
          <i className="fa fa-times" />
        }
      </td>
      <td>{listener.connection_limit}</td>
      <td>
        <StaticTags tags={listener.insert_headers_keys} />
      </td>
      <td> 
        {disabled ?
          <span className="info-text">{l7PolicyIDs.length}</span>
        :
        <CachedInfoPopover  popoverId={"l7policies-popover-"+listener.id} 
                    buttonName={l7PolicyIDs.length} 
                    title={<React.Fragment>L7 Policies<Link to="#" onClick={onClick} style={{float: 'right'}}>Show all</Link></React.Fragment>}
                    content={<CachedInfoPopoverContent l7PolicyIDs={l7PolicyIDs} cachedl7PolicyIDs={listener.cached_l7policies} onSelectListener={onSelectListener}/>} />
        }
      </td>
      <td>
        <div className='btn-group'>
          <button
            className='btn btn-default btn-sm dropdown-toggle'
            type="button"
            data-toggle="dropdown"
            aria-expanded={true}>
            <span className="fa fa-cog"></span>
          </button>
          <ul className="dropdown-menu dropdown-menu-right" role="menu">
            <li><a href='#' onClick={handleDelete}>Delete</a></li>
          </ul>
        </div>
      </td>
    </tr>
   );
}
 
export default ListenerItem;