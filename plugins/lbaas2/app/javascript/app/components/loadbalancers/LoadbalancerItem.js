import { Highlighter } from 'react-bootstrap-typeahead'
import { Link } from 'react-router-dom';
import LbPopover from './LbPoopover';
import LbPopoverListenerContent from './LbPopoverListenerContent';
import LbPopoverPoolContent from './LbPopoverPoolContent';
import StaticTags from '../StaticTags';
import StateLabel from '../StateLabel'
import useStatusTree from '../../../lib/hooks/useStatusTree'
import { useEffect } from 'react'
import useLoadbalancer from '../../../lib/hooks/useLoadbalancer'

const MyHighlighter = ({search,children}) => {
  if(!search || !children) return children
  return <Highlighter search={search}>{children+''}</Highlighter>
}

const LoadbalancerItem = React.memo(({loadbalancer, searchTerm, disabled}) => {  
  const {fetchLoadbalancer, deleteLoadbalancer} = useLoadbalancer()
  let polling = null
  // useStatusTree({lbId: loadbalancer.id})

  useEffect(() => {
    // console.group('provisioning_status')
    // console.log(loadbalancer.provisioning_status)
    // console.groupEnd()

    if(loadbalancer.provisioning_status.includes('PENDING')) {
      startPolling(5000)
    } else {
      startPolling(30000)
    }

    return function cleanup() {
      stopPolling()
    };
  });

  const startPolling = (interval) => {   
    // do not create a new polling interval if already polling
    if(polling) return;
    console.log("Polling loadbalancer -->", loadbalancer.id, " with interval -->", interval)
    polling = setInterval(() => {
      fetchLoadbalancer(loadbalancer.id).catch( (error) => {
        // console.log(JSON.stringify(error))
      })
    }, interval
    )
  }

  const stopPolling = () => {
    console.log("stop polling for id -->", loadbalancer.id)
    clearInterval(polling)
    polling = null
  }

  const handleDelete = (e) => {
    e.preventDefault()
    deleteLoadbalancer(loadbalancer.name, loadbalancer.id).then(() => {
      
    })
  }

  console.log('RENDER loadbalancer list item id-->', loadbalancer.id)

  const poolIds = loadbalancer.pools.map(p => p.id)
  const listenerIds = loadbalancer.listeners.map(l => l.id)
  return(
    <tr className={disabled ? "active" : ""}>
      <td className="snug-nowrap">
        {disabled ?
            <span className="info-text"><MyHighlighter search={searchTerm}>{loadbalancer.name || loadbalancer.id}</MyHighlighter></span>
         :
          <Link to={`/loadbalancers/${loadbalancer.id}/show`}>
            <MyHighlighter search={searchTerm}>{loadbalancer.name || loadbalancer.id}</MyHighlighter>
          </Link>
         }
        {loadbalancer.name && 
            <React.Fragment>
              <br/>
              <span className="info-text"><MyHighlighter search={searchTerm}>{loadbalancer.id}</MyHighlighter></span>
            </React.Fragment>
          }
      </td>
      <td><MyHighlighter search={searchTerm}>{loadbalancer.description}</MyHighlighter></td>
      <td><StateLabel placeholder={loadbalancer.operating_status} path="operating_status" /></td>
      <td><StateLabel placeholder={loadbalancer.provisioning_status} path="provisioning_status"/></td>
      {/* <td>{loadbalancer.operating_status}</td> */}
      {/* <td>{loadbalancer.provisioning_status}</td> */}
      <td>
        <StaticTags tags={loadbalancer.tags} />
      </td>
      <td className="snug-nowrap">
        {loadbalancer.subnet && 
          <React.Fragment>
            <p className="list-group-item-text" data-is-from-cache={loadbalancer.subnet_from_cache}>{loadbalancer.subnet.name}</p>
          </React.Fragment>
        }
        {loadbalancer.vip_address && 
          <React.Fragment>
            <p className="list-group-item-text">
              <i className="fa fa-desktop fa-fw"/>
              {loadbalancer.vip_address}
            </p>
          </React.Fragment>
        }
        {loadbalancer.floating_ip && 
          <React.Fragment>
            <p className="list-group-item-text">
              <i className="fa fa-globe fa-fw"/>
              {loadbalancer.floating_ip.floating_ip_address}
            </p>
          </React.Fragment>
        }
      </td>
      <td> 
        {disabled ?
          <span className="info-text">{listenerIds.length}</span>
        :
        <LbPopover  popoverId={"listener-popover-"+loadbalancer.id} 
                    buttonName={listenerIds.length} 
                    title={<React.Fragment>Listeners<Link to={`/listeners/`} style={{float: 'right'}}>Show all</Link></React.Fragment>}
                    content={<LbPopoverListenerContent listenerIds={listenerIds} cachedListeners={loadbalancer.cached_listeners}/>} />
        }
      </td>
      <td>
      {disabled ?
          <span className="info-text">{poolIds.length}</span>
        :
        <LbPopover  popoverId={"pools-popover-"+loadbalancer.id} 
                    buttonName={poolIds.length} 
                    title={<React.Fragment>Pools<Link to={`/pools/`} style={{float: 'right'}}>Show all</Link></React.Fragment>}
                    content={<LbPopoverPoolContent poolIds={poolIds} cachedPools={loadbalancer.cached_pools}/>} />
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
  )
},(oldProps,newProps) => {
  const identical = JSON.stringify(oldProps.loadbalancer) === JSON.stringify(newProps.loadbalancer) && 
                    oldProps.searchTerm === newProps.searchTerm && 
                    oldProps.disabled === newProps.disabled
  return identical                  
})

LoadbalancerItem.displayName = 'LoadbalancerItem';

export default LoadbalancerItem;